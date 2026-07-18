# -*- coding: utf-8 -*-
import json, csv, re
from collections import Counter, defaultdict

BASE="/tmp/claude-1000/-home-gabfelix-dev-4yu-apps-quanto-cobro/380763f2-12a7-49d2-81e1-b841eec3d56a/scratchpad"
rows=[json.loads(l) for l in open(f"{BASE}/reviews.jsonl")]

# titulos
title={}
for r in csv.DictReader(open(f"{BASE}/inventory.csv")): title[r["appId"]]=r["title"]
for a in json.load(open(f"{BASE}/curated_apps.json")): title.setdefault(a["appId"],a["title"])

# ---- DROP: intrusos fora do escopo (pricing + imposto/MEI) ----
DROP={
 "pt.cosmicode.imposter","de.devnova.imposter",   # jogos "Impostor"
 "com.mei",                                        # SMS/AI, nao MEI
 "com.aadhk.time","trasco.crist.calculadorajornada","com.barnasoba.timebetween", # horas trabalhadas
 "com.zapptax.zapptax","com.bfreetaxback.smarttax",# tax-free de turista
 "com.meilan.app",                                 # ambiguo
}
clean=[r for r in rows if r["appId"] not in DROP]
print(f"total bruto={len(rows)}  dropados={len(rows)-len(clean)}  LIMPO={len(clean)}")

def norm(s): return (s or "").lower()

# ---------- LEXICOS ----------
COMPLAINT={
 "cobranca_paywall": ["cobra","cobrança","cobranca","cobrado","cobraram","paguei","pagar pra","pagar para","assinatura","mensalidade","anual","caro","golpe","estorno","reembolso","devolv","pago pra","roubo","charged","expensive","refund","subscription","scam","rip off","pay to","paywall"],
 "anuncio":          ["anúncio","anuncio","propaganda","publicidad"," ads ","muito ad","cheio de an"],
 "bug_crash":        ["bug","trava","travando","não abre","nao abre","fecha sozinh","erro","crash","lento","bugad","parou de funcionar","não funciona","nao funciona","não carrega","doesn't work","crashes","freeze","glitch","not working","won't open"],
 "cadastro_forcado": ["cadastro","cadastrar","criar conta","obriga","fazer login","pede e-mail","pede email","meus dados","sign up","sign-up","register","account required","gov.br"],
 "gov_confusao":     ["governo","é oficial","nao e oficial","não é oficial","aplicativo do governo","se passa","engana","pensei que era"],
 "suporte_ruim":     ["suporte","atendimento","não respond","nao respond","sem resposta","ninguém responde","ninguem responde","support","no response","no reply","customer service"],
 "impreciso":        ["errado","incorreto","desatualizado","não bate","nao bate","valor errado","cálculo errado","calculo errado","não calcula","nao calcula","wrong","incorrect","inaccurate","outdated"],
 "confuso_complexo": ["complicado","confuso","difícil de","dificil de","não entendi","nao entendi","complexo","poluíd","confusing","complicated","hard to use","not intuitive","clunky"],
 "perda_dados":      ["perdi tudo","apagou","sumiu","perdeu os dados","zerou","lost data","deleted my","wiped"],
}
PRAISE={
 "facil_simples":    ["fácil","facil","simples","intuitivo","prátic","pratic","descomplicad","easy","simple","intuitive","user friendly","straightforward"],
 "util_resolve":     ["ajuda","ajudou","útil","util ","resolve","resolveu","salvou","recomendo","excelente","ótimo","otimo","maravilh","perfeit","adorei","amei","helpful","useful","great","excellent","love","amazing","perfect","recommend"],
 "gratis_sem_ad":    ["grátis","gratis","sem propaganda","sem anúncio","sem anuncio","de graça","de graca","free ","no ads","without ads"],
 "organiza_controle":["organiz","controle","controlar","em dia","lembrete","não esqueço","nao esqueço","keep track","reminder","on time","organized"],
 "rapido":           ["rápido","rapido","rapidinho","em segundos","fast","quick","in seconds"],
}
REQ=["poderia","podia ","seria bom","seria ótimo","seria otimo","falta ","faltou","sugest","gostaria que","deveria ter","deveria adicionar","adicionar","incluir","should add","please add","would be nice","wish it","needs a","add a"]

def hits(text, lex):
    return [k for k,words in lex.items() if any(w in text for w in words)]

def analyze(subset):
    neg=[r for r in subset if r["score"] in (1,2)]
    pos=[r for r in subset if r["score"] in (4,5)]
    neu=[r for r in subset if r["score"]==3]
    res={"n":len(subset),"neg":len(neg),"neu":len(neu),"pos":len(pos),
         "avg":round(sum(r["score"] for r in subset)/max(1,len(subset)),2)}
    # temas de reclamacao entre NEG
    cc=Counter(); cv=defaultdict(list)
    for r in neg:
        t=norm(r["content"])
        for k in hits(t,COMPLAINT):
            cc[k]+=1; cv[k].append(r)
    res["complaints"]={k:{"n":cc[k],"pct_neg":round(100*cc[k]/max(1,len(neg)),1)} for k in COMPLAINT}
    # temas de elogio entre POS
    pc=Counter(); pv=defaultdict(list)
    for r in pos:
        t=norm(r["content"])
        for k in hits(t,PRAISE):
            pc[k]+=1; pv[k].append(r)
    res["praises"]={k:{"n":pc[k],"pct_pos":round(100*pc[k]/max(1,len(pos)),1)} for k in PRAISE}
    # pedidos (qualquer nota)
    rq=[r for r in subset if any(w in norm(r["content"]) for w in REQ)]
    res["requests_n"]=len(rq)
    return res, cv, pv, rq

def top_verbatim(vlist, k=4, maxlen=200):
    seen=set(); out=[]
    for r in sorted(vlist,key=lambda x:(-(x["thumbs"] or 0),-len(x["content"]))):
        c=re.sub(r"\s+"," ",r["content"]).strip()
        if c[:60] in seen: continue
        seen.add(c[:60])
        out.append({"score":r["score"],"thumbs":r["thumbs"],"app":title.get(r["appId"],r["appId"])[:28],"text":c[:maxlen]})
        if len(out)>=k: break
    return out

report={"total_clean":len(clean)}
for label, subset in [("GERAL",clean),
                      ("PRICING",[r for r in clean if r["bucket"]=="pricing"]),
                      ("TAX_MEI",[r for r in clean if r["bucket"]=="tax_mei"])]:
    res,cv,pv,rq=analyze(subset)
    report[label]={"stats":res}
    if label=="GERAL":
        report[label]["complaint_verbatims"]={k:top_verbatim(cv[k]) for k in COMPLAINT if cv[k]}
        report[label]["praise_verbatims"]={k:top_verbatim(pv[k]) for k in PRAISE if pv[k]}
        report[label]["request_verbatims"]=top_verbatim(rq,6)

json.dump(report,open(f"{BASE}/categorization.json","w"),ensure_ascii=False,indent=1)

# ---------- IMPRESSAO DIGESTO ----------
def show(label):
    s=report[label]["stats"]
    print(f"\n===== {label}  (n={s['n']}, média={s['avg']}★, neg={s['neg']} {round(100*s['neg']/max(1,s['n']))}% · pos={s['pos']} {round(100*s['pos']/max(1,s['n']))}%) =====")
    print("  RECLAMAÇÕES (% dos negativos):")
    for k,v in sorted(s["complaints"].items(),key=lambda x:-x[1]["n"]):
        if v["n"]: print(f"     {v['pct_neg']:5.1f}%  {v['n']:4d}  {k}")
    print("  ELOGIOS (% dos positivos):")
    for k,v in sorted(s["praises"].items(),key=lambda x:-x[1]["n"]):
        if v["n"]: print(f"     {v['pct_pos']:5.1f}%  {v['n']:4d}  {k}")
    print(f"  pedidos de recurso: {s['requests_n']}")
for l in ["GERAL","TAX_MEI","PRICING"]: show(l)

# apps: pior reputacao
print("\n===== APPS por satisfação (n>=100) =====")
byapp=defaultdict(list)
for r in clean: byapp[r["appId"]].append(r)
tab=[]
for a,rs in byapp.items():
    if len(rs)<100: continue
    avg=sum(x["score"] for x in rs)/len(rs)
    negpct=100*sum(1 for x in rs if x["score"]in(1,2))/len(rs)
    tab.append((avg,negpct,len(rs),title.get(a,a)[:34],a))
for avg,negpct,n,t,a in sorted(tab):
    print(f"   {avg:.2f}★  neg {negpct:4.0f}%  n={n:4d}  {t}")
print("\nOK -> categorization.json")
