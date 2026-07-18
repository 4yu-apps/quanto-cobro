import time, json, csv
from google_play_scraper import search, app

# ---- termos por espaco funcional (multi-lingua) ----
TERMS = {
 "pricing":   ["precificação","quanto cobrar","calculadora freelancer","valor hora",
               "freelance rate calculator","hourly rate calculator","pricing calculator",
               "calculadora tarifa freelance","precios freelance"],
 "tax_mei":   ["MEI","DAS MEI","imposto autônomo","carnê leão","nota fiscal MEI",
               "self employed tax","freelance tax","autónomo impuestos","1099 tax"],
 "invoice":   ["invoice freelancer","invoice maker","fatura autônomo","boleto",
               "cobrança","recibo autônomo","facturas autónomos","invoice app"],
 "freelance": ["freelancer","freelance app","trabalho autônomo","gig work"],
 "time":      ["time tracker freelance","timesheet hourly","controle de horas"],
}
COUNTRIES = [("br","pt"),("us","en"),("gb","en"),("es","es"),("mx","es"),("in","en")]

# ids que a fase 1 ja achou (garante que entram)
SEED = ["com.abp.freelancer_calculator","com.aleckrh.freelancecalculator",
        "com.b20robots.calculadoravalorhora","com.tfs.thefreelancesuite_android",
        "app.freelancecalc","com.zoho.invoice","com.toggl.giskard"]

cand = set(SEED)
print("== varrendo busca ==", flush=True)
for bucket, terms in TERMS.items():
    for t in terms:
        for ct,lg in COUNTRIES:
            try:
                for r in search(t, lang=lg, country=ct, n_hits=6):
                    cand.add(r["appId"])
            except Exception:
                pass
            time.sleep(0.15)
cand = {c for c in cand if isinstance(c, str) and c}
print("candidatos unicos:", len(cand), flush=True)

def bucket_of(title):
    t=(title or "").lower()
    kw=[("pricing",["precifica","quanto cobr","valor hora","valor/hora","rate calc","hourly rate","pricing","preço de venda","precio"]),
        ("tax_mei",["mei","imposto","das","darf","carnê","carne leao","tax","autónomo","autonomo","self employed","vat","1099","impuesto"]),
        ("invoice",["invoice","fatura","factura","nota fiscal","boleto","cobrança","cobranca","billing","recibo"]),
        ("time",["time track","timesheet","horas","clock","toggl","hours"]),
        ("freelance",["freelance","freelancer","autonomo","autônomo","gig"])]
    for b,words in kw:
        if any(w in t for w in words): return b
    return "outro"

rows=[]
print("== puxando metadados ==", flush=True)
for i,pkg in enumerate(sorted(cand)):
    got=None
    for ct,lg in [("br","pt"),("us","en")]:
        try:
            a=app(pkg,lang=lg,country=ct)
            if a and (a.get("reviews") or a.get("ratings")):
                got=a; break
        except Exception:
            pass
        time.sleep(0.1)
    if not got:
        continue
    rows.append({
        "appId":pkg,
        "title":(got.get("title") or "")[:45],
        "bucket":bucket_of(got.get("title")),
        "score":round(got.get("score") or 0,2),
        "ratings":got.get("ratings") or 0,
        "reviews":got.get("reviews") or 0,   # reviews de TEXTO
        "installs":got.get("installs") or "?",
        "genre":got.get("genre") or "",
    })
    if i%25==0: print(f"  ...{i}/{len(cand)}", flush=True)

rows.sort(key=lambda r:r["reviews"], reverse=True)
out="/tmp/claude-1000/-home-gabfelix-dev-4yu-apps-quanto-cobro/380763f2-12a7-49d2-81e1-b841eec3d56a/scratchpad/inventory.csv"
with open(out,"w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)

# ---- SUMARIO QUANTIFICADO ----
tot_text=sum(r["reviews"] for r in rows)
tot_rat=sum(r["ratings"] for r in rows)
print("\n===== QUANTIFICACAO =====")
print(f"apps com dados: {len(rows)}")
print(f"reviews de TEXTO somados (pais primario): {tot_text:,}")
print(f"notas (ratings) somadas: {tot_rat:,}")
from collections import defaultdict
bt=defaultdict(lambda:[0,0,0])
for r in rows:
    b=bt[r["bucket"]]; b[0]+=1; b[1]+=r["reviews"]; b[2]+=r["ratings"]
print("\npor categoria:  apps | reviews_texto | ratings")
for b,(n,rv,rt) in sorted(bt.items(),key=lambda x:-x[1][1]):
    print(f"  {b:10s}  {n:4d} | {rv:9,} | {rt:11,}")
print("\nTOP 20 por reviews de texto:")
for r in rows[:20]:
    print(f"  {r['reviews']:7,}  {r['score']:.2f}  [{r['bucket']:9s}] {r['title']}  ({r['appId']})")
print("\ncsv:", out)
