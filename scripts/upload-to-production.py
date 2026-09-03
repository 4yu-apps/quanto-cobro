#!/usr/bin/env python3
"""Sobe um AAB novo DIRETO na faixa de produção, sem passar por teste interno.

O irmão do `promote-to-production.py`, pro caso em que não existe binário na
Play ainda. Aquele só aponta a produção pra um versionCode que já vive numa
faixa; este faz o upload do arquivo e publica no mesmo movimento.

  set -a && . ../.secrets/4yu.env && set +a
  python3 scripts/upload-to-production.py                 # dry-run (padrão)
  python3 scripts/upload-to-production.py --commit        # publica de verdade

**Dry-run é o padrão de propósito.** Sem --commit o script sobe o AAB, monta a
release, chama validate e DESCARTA a edit: o Google confere tudo e nada vai ao
ar. O upload em si é inofensivo enquanto a edit não for commitada.

Teste interno não é obrigatório. O relógio de 12 x 14 dias corre no teste
FECHADO, e essa conta já passou por ele (0.9.2 publicada em 23/ago/2026). O
checklist que o console oferece é sugestão, não portão. O que a Play exige de
verdade é só que o versionCode seja maior que o que já está publicado.

PRÉ-REQUISITO QUE SÓ EXISTE NA UI: a faixa de produção precisa ter países
selecionados (Produção -> Países e regiões). Sem isso o validate responde
`403 Release in track targeting no countries`. Não há endpoint de escrita pra
country availability na AndroidPublisher v3.
"""
import argparse, base64, json, os, subprocess, sys, tempfile, time
import urllib.request, urllib.error, urllib.parse

PKG = "com.fouryuapps.quantocobro"
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PKG}"
UPLOAD = ("https://androidpublisher.googleapis.com/upload/androidpublisher/v3/"
          f"applications/{PKG}/edits/{{edit}}/bundles?uploadType=media")


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


def upload_aab(tok, edit_id, path):
    """Upload simples (uploadType=media). 70 MB cabe de sobra; sem resumable."""
    with open(path, "rb") as f:
        blob = f.read()
    req = urllib.request.Request(
        UPLOAD.format(edit=edit_id), data=blob, method="POST",
        headers={"Authorization": f"Bearer {tok}",
                 "Content-Type": "application/octet-stream",
                 "Content-Length": str(len(blob))})
    try:
        r = urllib.request.urlopen(req, timeout=900)
        return json.loads(r.read().decode() or "{}"), None
    except urllib.error.HTTPError as e:
        return None, (e.code, e.read().decode()[:600].replace("\n", " "))


# Espelha a seção "Novidades" de docs/planning/14-FICHA-LOJA.md. As duas
# precisam dizer a mesma coisa: esta vai pela API, aquela é a que se cola no
# console. O campo da Play aceita 500 caracteres.
NOTES = ("O passo das horas ficou claro: agora dá pra ver a conta antes de "
         "aceitar a resposta.\n\n"
         "Novo: Simulador de folga. Diga quantos dias quer parar e o app "
         "mostra quanto a sua hora precisa subir pra pagar essa folga.\n\n"
         "A proposta ganhou prazo de entrega e forma de pagamento. O trabalho "
         "ganhou data de entrega, com o quanto falta.\n\n"
         "O orçamento avisa quando o projeto pede mais hora do que o mês tem."
         "\n\n"
         "Visual novo: o Teto do MEI virou anel, o \"Recebi\" agora fica "
         "sempre à mão, e o Início ganhou atalhos.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--aab", default="build/app/outputs/bundle/release/app-release.aab")
    ap.add_argument("--name", default="0.11.0", help="nome da release no console")
    ap.add_argument("--commit", action="store_true",
                    help="publica de verdade (sem isso: valida e descarta)")
    args = ap.parse_args()

    if not os.path.exists(args.aab):
        sys.exit(f"AAB não encontrado: {args.aab}\n"
                 f"Rode antes: flutter build appbundle --release")
    mb = os.path.getsize(args.aab) / 1e6
    print(f"AAB: {args.aab} ({mb:.1f} MB)")

    tok = token()

    # O que está no ar HOJE, antes de mexer em nada.
    edit0, e = call(tok, f"{API}/edits", "POST", {})
    if e: sys.exit(f"abrir edit de leitura: {e}")
    prod0, _ = call(tok, f"{API}/edits/{edit0['id']}/tracks/production")
    atuais = [vc for r in (prod0 or {}).get("releases", [])
              for vc in (r.get("versionCodes") or [])]
    print("produção hoje:", ", ".join(atuais) or "(vazia)")
    call(tok, f"{API}/edits/{edit0['id']}", "DELETE")

    edit, e = call(tok, f"{API}/edits", "POST", {})
    if e: sys.exit(f"abrir edit: {e}")
    base = f"{API}/edits/{edit['id']}"

    committed = False
    try:
        print("subindo o AAB (pode demorar)...")
        b, e = call_up = upload_aab(tok, edit["id"], args.aab)
        if e: sys.exit(f"upload: {e}")
        vc = str(b.get("versionCode"))
        print(f"upload OK: versionCode {vc}")

        if atuais and int(vc) <= max(int(x) for x in atuais):
            sys.exit(f"versionCode {vc} não é maior que o que já está em "
                     f"produção ({', '.join(atuais)}). A Play recusaria.")

        body = {"track": "production",
                "releases": [{"name": args.name,
                              "versionCodes": [vc],
                              "status": "completed",
                              "releaseNotes": [{"language": "pt-BR", "text": NOTES}]}]}
        _, e = call(tok, f"{base}/tracks/production", "PUT", body)
        if e: sys.exit(f"montar release: {e}")

        _, e = call(tok, f"{base}:validate", "POST")
        if e:
            if "targeting no countries" in str(e):
                sys.exit("VALIDATE recusou: a faixa de produção não tem países "
                         "selecionados. Play Console -> Produção -> Países e "
                         "regiões. Só existe na UI.")
            sys.exit(f"validate (NÃO commitei): {e}")
        print("validate: OK")

        if not args.commit:
            print("\nDRY-RUN, nada foi publicado. Use --commit pra valer.")
            return

        _, e = call(tok, f"{base}:commit", "POST")
        if e: sys.exit(f"commit: {e}")
        committed = True
        print(f"PUBLICADO: versionCode {vc} ({args.name}) em produção.")
    finally:
        if not committed:
            call(tok, base, "DELETE")

    # relê de fora da edit: "commitou" e "está no ar" não são a mesma coisa
    edit2, e = call(tok, f"{API}/edits", "POST", {})
    if not e:
        prod, _ = call(tok, f"{API}/edits/{edit2['id']}/tracks/production")
        print("\nprodução agora:", json.dumps(prod, indent=2, ensure_ascii=False))
        call(tok, f"{API}/edits/{edit2['id']}", "DELETE")


if __name__ == "__main__":
    main()
