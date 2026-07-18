/* ============================================================
   QUANTO EU COBRO?  ·  app.jsx
   Shell: navegação hub-and-spoke, temas, status bar, rail de review, Tweaks.
   ============================================================ */

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "dark",
  "estado": "calculo",
  "reduceMotion": false,
  "showAd": true
}/*EDITMODE-END*/;

const SCREENS = [
  { id: "painel",    label: "Painel",         icon: "home" },
  { id: "calc",      label: "Calculadora",    icon: "calculate" },
  { id: "result",    label: "Resultado",      icon: "insights" },
  { id: "detalhe",   label: "Detalhamento",   icon: "receipt_long" },
  { id: "reserva",   label: "Reserva",        icon: "savings" },
  { id: "simulador", label: "Simulador",      icon: "request_quote" },
  { id: "perfis",    label: "Perfis",         icon: "switch_account" },
  { id: "config",    label: "Configurações",  icon: "settings" },
  { id: "pro",       label: "Pro",            icon: "workspace_premium" },
];

function cloneProfile(p) { return JSON.parse(JSON.stringify(p)); }

/* status bar do aparelho */
function StatusBar() {
  return (
    <div className="qc-statusbar">
      <span className="qc-sb-time tnum">9:41</span>
      <span className="qc-sb-icons">
        <Icon name="signal_cellular_alt" size={16} />
        <Icon name="wifi" size={16} />
        <Icon name="battery_full" size={16} />
      </span>
    </div>
  );
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [screen, setScreen] = useState(() => localStorage.getItem("qc-screen") || "painel");
  const [profile, setProfile] = useState(defaultProfile);
  const [draft, setDraft] = useState(defaultProfile);
  const [snackMsg, setSnackMsg] = useState("");
  const snackTimer = useRef(0);

  const theme = t.theme;
  const hasProfile = t.estado === "calculo";

  useEffect(() => { window.__qcReduceMotion = !!t.reduceMotion; }, [t.reduceMotion]);
  useEffect(() => { localStorage.setItem("qc-screen", screen); }, [screen]);

  const go = (s) => {
    if (s === "calc") setDraft(cloneProfile(profile));
    setScreen(s);
    document.querySelector(".qc-scroll")?.scrollTo?.(0, 0);
  };
  const snack = (msg) => {
    setSnackMsg(msg);
    clearTimeout(snackTimer.current);
    snackTimer.current = setTimeout(() => setSnackMsg(""), 3200);
  };

  const compProfile = computeValorHora(profile);
  const compDraft = computeValorHora(draft);

  const saveProfile = () => { setProfile(cloneProfile(draft)); setTweak("estado", "calculo"); snack("Perfil salvo"); go("painel"); };
  const wipe = () => { setProfile(defaultProfile()); setTweak("estado", "vazio"); snack("Dados apagados"); go("painel"); };

  let content;
  switch (screen) {
    case "painel":    content = hasProfile ? <PainelScreen profile={profile} comp={compProfile} go={go} snack={snack} showAd={t.showAd} /> : <VazioScreen go={go} />; break;
    case "calc":      content = <CalcScreen draft={draft} setDraft={setDraft} go={go} onFinish={() => go("result")} />; break;
    case "result":    content = <ResultadoScreen profile={draft} comp={compDraft} go={go} onSave={saveProfile} onPro={() => go("pro")} />; break;
    case "detalhe":   content = <DetalheScreen profile={profile} setProfile={setProfile} comp={compProfile} go={go} />; break;
    case "reserva":   content = <ReservaScreen profile={profile} go={go} />; break;
    case "simulador": content = <SimuladorScreen profile={profile} comp={compProfile} go={go} />; break;
    case "perfis":    content = <PerfisScreen go={go} />; break;
    case "config":    content = <ConfigScreen go={go} theme={theme} onToggleTheme={() => setTweak("theme", theme === "dark" ? "light" : "dark")} onWipe={wipe} snack={snack} />; break;
    case "pro":       content = <ProScreen go={go} snack={snack} />; break;
    default:          content = <PainelScreen profile={profile} comp={compProfile} go={go} snack={snack} />;
  }

  return (
    <div className="qc-stage">
      <aside className="qc-rail">
        <div className="qc-rail-brand">
          <div className="qc-rail-logo"><span className="material-symbols-rounded fill">savings</span></div>
          <div>
            <p className="qc-rail-title">Quanto eu Cobro<span style={{ color: "var(--qc-accent)" }}>?</span></p>
            <p className="qc-rail-sub">Protótipo hi-fi · “A Divisão”</p>
          </div>
        </div>

        <div className="qc-rail-section">Tema</div>
        <div className="qc-rail-seg">
          <button className={theme === "dark" ? "on" : ""} onClick={() => setTweak("theme", "dark")}><Icon name="dark_mode" size={16} />Escuro</button>
          <button className={theme === "light" ? "on" : ""} onClick={() => setTweak("theme", "light")}><Icon name="light_mode" size={16} />Claro</button>
        </div>

        <div className="qc-rail-section">Painel</div>
        <div className="qc-rail-seg">
          <button className={hasProfile ? "on" : ""} onClick={() => { setTweak("estado", "calculo"); go("painel"); }}>Com cálculo</button>
          <button className={!hasProfile ? "on" : ""} onClick={() => { setTweak("estado", "vazio"); go("painel"); }}>Primeiro uso</button>
        </div>

        <div className="qc-rail-section">Telas</div>
        <nav className="qc-rail-nav">
          {SCREENS.map((s) => (
            <button key={s.id} className={"qc-rail-link" + (screen === s.id ? " on" : "")} onClick={() => go(s.id)}>
              <Icon name={s.icon} size={18} /><span>{s.label}</span>
            </button>
          ))}
        </nav>

        <p className="qc-rail-foot">Mobile-first 390×844 · tema escuro padrão. Ajuste tema, estado e movimento no painel Tweaks.</p>
      </aside>

      <main className="qc-phone-wrap">
        <div className="qc-device">
          <div className={"qc-app" + (t.reduceMotion ? " qc-reduce" : "")} data-theme={theme}>
            <StatusBar />
            <div className="qc-viewport">{content}</div>
            <Snackbar msg={snackMsg} />
          </div>
        </div>
      </main>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Tema" />
        <TweakRadio label="Aparência" value={theme} options={["dark", "light"]} onChange={(v) => setTweak("theme", v)} />
        <TweakSection label="Conteúdo" />
        <TweakRadio label="Estado do Painel" value={t.estado} options={["calculo", "vazio"]} onChange={(v) => { setTweak("estado", v); go("painel"); }} />
        <TweakToggle label="Mostrar publicidade" value={t.showAd} onChange={(v) => setTweak("showAd", v)} />
        <TweakSection label="Acessibilidade" />
        <TweakToggle label="Reduzir movimento" value={t.reduceMotion} onChange={(v) => setTweak("reduceMotion", v)} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
