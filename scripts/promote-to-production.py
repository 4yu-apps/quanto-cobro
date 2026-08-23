#!/usr/bin/env python3
"""Promove um versionCode que JÁ está no Play para a faixa de produção.

Não builda e não sobe binário: o AAB já foi assinado pelo Play e já vive nas
faixas de teste. Promover é só apontar a produção pro mesmo versionCode — é por
isso que lançar não exige build novo.

  set -a && . ../.secrets/4yu.env && set +a
  python3 scripts/promote-to-production.py                 # dry-run (padrão)
  python3 scripts/promote-to-production.py --commit        # publica de verdade

**Dry-run é o padrão de propósito.** Sem --commit o script monta a release,
chama validate e descarta a edit: o Google confere tudo e nada vai ao ar.

PRÉ-REQUISITO QUE SÓ EXISTE NA UI: a faixa de produção precisa ter países
selecionados (Produção → Países e regiões). Sem isso o validate responde
`403 Release in track targeting no countries`. Não há endpoint de escrita pra
country availability na AndroidPublisher v3 — o `countryTargeting` da release só
vale pra rollout parcial, e a PRIMEIRA release de uma faixa não pode ser parcial.
Os dois caminhos se fecham; a UI é o único jeito.
"""
import argparse, base64, json, os, subprocess, sys, tempfile, time
import urllib.request, urllib.error, urllib.parse

PKG = "com.fouryuapps.quantocobro"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PKG}"


def token():
    d = json.load(open(os.environ["PLAY_SA_JSON"]))
    b64 = lambda x: base64.urlsafe_b64encode(x).decode().rstrip("=")
    now = int(time.time())
    claim = {"iss": d["client_email"],
             "scope": "https://www.googleapis.com/auth/androidpublisher",
             "aud": d["token_uri"], "iat": now, "exp": now + 3600}
    si = f'{b64(json.dumps({"alg":"RS256","typ":"JWT"}).encode())}.{b64(json.dumps(claim).encode())}'
    with tempfile.NamedTemporaryFile("w", suffix=".pem", delete=False) as f:
        f.write(d["private_key"]); key = f.name
    sig = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key],
                         input=si.encode(), capture_output=True).stdout
    os.unlink(key)
    body = urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": f"{si}.{b64(sig)}"}).encode()
    return json.load(urllib.request.urlopen(
        urllib.request.Request(d["token_uri"], data=body)))["access_token"]


def call(tok, url, method="GET", data=None):
    h = {"Authorization": f"Bearer {tok}"}
    payload = None
    if data is not None:
        h["Content-Type"] = "application/json"; payload = json.dumps(data).encode()
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers=h, data=payload, method=method))
        return json.loads(r.read().decode() or "{}"), None
    except urllib.error.HTTPError as e:
        return None, (e.code, e.read().decode()[:600].replace("\n", " "))


# Notas de versão aparecem na loja pro usuário final — aqui acento não é
# detalhe, é a diferença entre parecer um app cuidado e um app largado.
# Escritas a partir da própria ficha: nada aqui promete o que o app não faz.
NOTES = ("Primeira versão pública do Quanto Cobro?.\n\n"
         "Descubra quanto cobrar por hora e por projeto a partir do que você "
         "quer ganhar livre, separe o imposto certo a cada pagamento (MEI, "
         "Simples, carnê-leão e renda do exterior) e monte propostas em PDF. "
         "Funciona offline, sem cadastro.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--version-code", default="20")
    ap.add_argument("--name", default="0.9.2", help="nome da release no console")
    ap.add_argument("--commit", action="store_true",
                    help="publica de verdade (sem isso: valida e descarta)")
    args = ap.parse_args()

    tok = token()

    edit, e = call(tok, f"{API}/edits", "POST", {})
    if e: sys.exit(f"abrir edit: {e}")
    base = f"{API}/edits/{edit['id']}"

    committed = False
    try:
        # promover o que ninguém testou é lançar às cegas, e o Play deixa
        tracks, e = call(tok, f"{base}/tracks")
        if e: sys.exit(f"ler tracks: {e}")
        testado = [t["track"] for t in tracks.get("tracks", [])
                   for r in t.get("releases", [])
                   if args.version_code in (r.get("versionCodes") or [])]
        if not testado:
            sys.exit(f"versionCode {args.version_code} não está em nenhuma faixa "
                     f"de teste — promova só o que já foi testado.")
        print(f"versionCode {args.version_code} já está em: {', '.join(testado)}")

        body = {"track": "production",
                "releases": [{"name": args.name,
                              "versionCodes": [str(args.version_code)],
                              "status": "completed",
                              "releaseNotes": [{"language": "pt-BR", "text": NOTES}]}]}
        _, e = call(tok, f"{base}/tracks/production", "PUT", body)
        if e: sys.exit(f"montar release: {e}")

        _, e = call(tok, f"{base}:validate", "POST")
        if e:
            if "targeting no countries" in str(e):
                sys.exit("VALIDATE recusou: a faixa de produção não tem países "
                         "selecionados. Play Console → Produção → Países e "
                         "regiões. Só existe na UI.")
            sys.exit(f"validate (NÃO commitei): {e}")
        print("validate: OK")

        if not args.commit:
            print("\nDRY-RUN — nada foi publicado. Use --commit pra valer.")
            return

        _, e = call(tok, f"{base}:commit", "POST")
        if e: sys.exit(f"commit: {e}")
        committed = True
        print(f"PUBLICADO: versionCode {args.version_code} em produção.")
    finally:
        if not committed:
            call(tok, base, "DELETE")

    # relê de fora da edit, porque "commitou" e "está no ar" não são a mesma coisa
    edit2, e = call(tok, f"{API}/edits", "POST", {})
    if not e:
        prod, _ = call(tok, f"{API}/edits/{edit2['id']}/tracks/production")
        print("\nprodução agora:", json.dumps(prod, indent=2, ensure_ascii=False))
        call(tok, f"{API}/edits/{edit2['id']}", "DELETE")


if __name__ == "__main__":
    main()
