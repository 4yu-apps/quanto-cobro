import csv, json, time, sys
from google_play_scraper import reviews, Sort

BASE="/tmp/claude-1000/-home-gabfelix-dev-4yu-apps-quanto-cobro/380763f2-12a7-49d2-81e1-b841eec3d56a/scratchpad"
LOG=open(f"{BASE}/puller.log","w")
def log(*a):
    m=" ".join(str(x) for x in a); LOG.write(m+"\n"); LOG.flush(); print(m,flush=True)

CATS={"pricing","tax_mei"}
SEED_PRICING=[  # calculadoras de freelancer diretas (fase 1) — poucas reviews mas incluir
 "com.abp.freelancer_calculator","com.aleckrh.freelancecalculator",
 "com.b20robots.calculadoravalorhora","app.freelancecalc","com.tfs.thefreelancesuite_android",
]
NOISE={"com.mt.mtxx.mtxx"}  # Meitu (entrou por 'MEI')
TAX_KW=["mei","das","imposto","inss","darf","carn","tax","fiscal","autonom","autônom",
        "receita","leao","leão","impuesto","vat","tribut","contab"]

# ---- monta lista curada ----
apps={}
for r in csv.DictReader(open(f"{BASE}/inventory.csv")):
    b=r["bucket"]; pkg=r["appId"]; title=r["title"]
    if b not in CATS or pkg in NOISE: continue
    if b=="tax_mei" and not any(k in title.lower() for k in TAX_KW):
        log("  [pula ruido tax]",title,pkg); continue
    apps[pkg]={"appId":pkg,"bucket":b,"title":title}
for pkg in SEED_PRICING:
    apps.setdefault(pkg,{"appId":pkg,"bucket":"pricing","title":"(seed)"})

applist=list(apps.values())
json.dump(applist,open(f"{BASE}/curated_apps.json","w"),ensure_ascii=False,indent=1)
log(f"APPS CURADOS: {len(applist)}  (pricing={sum(1 for a in applist if a['bucket']=='pricing')}, tax_mei={sum(1 for a in applist if a['bucket']=='tax_mei')})")

COUNTRIES=[("br","pt"),("us","en"),("gb","en"),("es","es"),("mx","es")]
CAP=1500  # por app, somando paises

def pull_page(pkg,lg,ct,tok):
    for attempt in range(3):
        try:
            return reviews(pkg,lang=lg,country=ct,sort=Sort.NEWEST,count=200,continuation_token=tok)
        except Exception as e:
            time.sleep(1.5*(attempt+1))
    return [],None

out=open(f"{BASE}/reviews.jsonl","w")
seen=set()  # dedup por (appId, reviewId)
grand=0
for idx,a in enumerate(applist):
    pkg=a["appId"]; got=0
    for ct,lg in COUNTRIES:
        if got>=CAP: break
        tok=None
        while got<CAP:
            r,tok=pull_page(pkg,lg,ct,tok)
            if not r: break
            for rv in r:
                key=(pkg,rv.get("reviewId"))
                if key in seen: continue
                seen.add(key)
                out.write(json.dumps({
                    "appId":pkg,"bucket":a["bucket"],"country":ct,
                    "score":rv.get("score"),
                    "content":rv.get("content") or "",
                    "thumbs":rv.get("thumbsUpCount") or 0,
                    "at":str(rv.get("at")),
                },ensure_ascii=False)+"\n")
                got+=1
            if not tok: break
            time.sleep(0.2)
    grand+=got
    log(f"[{idx+1}/{len(applist)}] {pkg[:40]:40s} {a['bucket']:8s} -> {got:5d}  (total {grand})")
out.close()
log(f"\nDONE. total reviews salvos: {grand}")
LOG.close()
