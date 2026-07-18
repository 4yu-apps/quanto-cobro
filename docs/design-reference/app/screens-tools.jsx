/* ============================================================
   QUANTO EU COBRO?  ·  screens-tools.jsx
   6. Reserva (tool)  ·  7. Simulador de projeto (tool)
   ============================================================ */

/* barra colapsada do tool de Reserva: Reserva (azul) + Sobra (verde) */
function ReservaBar({ reserva, sobra }) {
  const total = reserva + sobra;
  const [shown, setShown] = useState(false);
  useEffect(() => {
    if (prefersReduced()) { setShown(true); return; }
    const id = requestAnimationFrame(() => requestAnimationFrame(() => setShown(true)));
    return () => cancelAnimationFrame(id);
  }, [reserva, sobra]);
  return (
    <div className="qc-divisao">
      <div className="qc-divisao-track" style={{ height: 20 }} role="img"
        aria-label={`Reserva ${fmtBRL(reserva)}, ${pct(reserva, total)} por cento. Sobra ${fmtBRL(sobra)}.`}>
        <div className="qc-seg" style={{ width: (shown ? pct(reserva, total) : 0) + "%", background: "var(--divisao-reserva)", borderRadius: "var(--radius-sm) 0 0 var(--radius-sm)" }} />
        <div className="qc-seg" style={{ width: (shown ? pct(sobra, total) : 0) + "%", background: "var(--divisao-lucro)", borderRadius: "0 var(--radius-sm) var(--radius-sm) 0" }} />
      </div>
      <ul className="qc-legend">
        <li className="qc-legend-item hot">
          <span className="qc-dot" style={{ background: "var(--divisao-reserva)" }} />
          <span className="qc-legend-label"><Icon name="savings" size={15} style={{ color: "var(--divisao-reserva)", transform: "translateY(2px)" }} /><span>Reserva (do leão)</span></span>
          <span className="qc-legend-val tnum">{fmtBRL(reserva)}</span>
          <span className="qc-legend-pct tnum">{pct(reserva, total)}%</span>
        </li>
        <li className="qc-legend-item">
          <span className="qc-dot" style={{ background: "var(--divisao-lucro)" }} />
          <span className="qc-legend-label"><Icon name="account_balance_wallet" size={15} style={{ color: "var(--divisao-lucro)", transform: "translateY(2px)" }} /><span>Sobra pra usar</span></span>
          <span className="qc-legend-val tnum">{fmtBRL(sobra)}</span>
          <span className="qc-legend-pct tnum">{pct(sobra, total)}%</span>
        </li>
      </ul>
    </div>
  );
}

/* seletor de regime (herdado do perfil, editável pontualmente) */
function RegimePicker({ regimeId, onPick }) {
  const [open, setOpen] = useState(false);
  return (
    <React.Fragment>
      <button className="qc-regime-select" onClick={() => setOpen(true)}>
        <Icon name="work" size={18} />
        <span>Regime: <strong>{REGIMES[regimeId].tag}</strong></span>
        <Icon name="expand_more" size={18} />
      </button>
      <Sheet open={open} onClose={() => setOpen(false)} title="Como você recebe?">
        <div className="qc-regime-list">
          {Object.values(REGIMES).map((r) => (
            <button key={r.id} className={"qc-regime-opt" + (regimeId === r.id ? " sel" : "")} onClick={() => { onPick(r.id); setOpen(false); }}>
              <span className="qc-radio">{regimeId === r.id && <span className="qc-radio-dot" />}</span>
              <span className="qc-regime-text"><strong>{r.label}</strong><small>{r.sub} · reserve ~{Math.round(r.reserveRate * 100)}%</small></span>
            </button>
          ))}
        </div>
      </Sheet>
    </React.Fragment>
  );
}

/* ---------- 6. RESERVA ---------- */
function ReservaScreen({ profile, go }) {
  const [amount, setAmount] = useState(2000);
  const [regime, setRegime] = useState(profile.regime);
  const r = computeReserva(amount, regime);
  const has = amount > 0;
  return (
    <div className="qc-screen">
      <AppBar title="Recebi um pagamento" onBack={() => go("painel")} />
      <div className="qc-scroll">
        <MoneyField label="Quanto você recebeu?" value={amount} onChange={setAmount} autoFocus big />

        {has ? (
          <React.Fragment>
            <section className="qc-result-block hero" style={{ marginTop: 8 }}>
              <p className="qc-overline">RESERVE PARA IMPOSTO</p>
              <div className="qc-result-line">
                <HeroValue value={r.reserva} prefix="R$" size="hero" color="var(--divisao-reserva)" deps={[r.reserva, regime]} />
                <span className="qc-result-aside tnum">({r.pct}%)</span>
              </div>
              <p className="qc-hero-context">Sobra pra usar: <strong className="tnum" style={{ color: "var(--divisao-lucro)" }}>{fmtBRL(r.sobra)}</strong></p>
            </section>

            <section className="qc-card">
              <ReservaBar reserva={r.reserva} sobra={r.sobra} />
            </section>

            <div className="qc-tool-foot">
              <RegimePicker regimeId={regime} onPick={setRegime} />
              <Seal short />
            </div>
          </React.Fragment>
        ) : (
          <div className="qc-tool-empty">
            <Icon name="savings" size={40} />
            <p>Digite o valor que caiu e eu já te digo quanto guardar.</p>
          </div>
        )}
      </div>
    </div>
  );
}

/* ---------- 7. SIMULADOR ---------- */
function SimuladorScreen({ profile, comp, go }) {
  const [valor, setValor] = useState(3000);
  const [horas, setHoras] = useState(30);
  const [custos, setCustos] = useState(200);
  const alvo = comp.valorHora;
  const s = computeSimulador(valor, horas, custos, profile.regime, alvo);
  const ready = valor > 0 && horas > 0;
  return (
    <div className="qc-screen">
      <AppBar title="Vou orçar um projeto" onBack={() => go("painel")} />
      <div className="qc-scroll">
        <div className="qc-sim-inputs">
          <MoneyField label="Valor do projeto" value={valor} onChange={setValor} big={false} />
          <div className="qc-field">
            <label className="qc-field-label">Horas estimadas</label>
            <div className="qc-field-box">
              <input className="qc-field-input tnum" inputMode="numeric" pattern="[0-9]*" style={{ fontSize: 28 }}
                value={horas > 0 ? _num0.format(horas) : ""} placeholder="0"
                onChange={(e) => { const d = e.target.value.replace(/\D/g, ""); setHoras(d ? parseInt(d, 10) : 0); }}
                onFocus={(e) => e.target.select()} aria-label="Horas estimadas" />
              <span className="qc-field-prefix" style={{ fontSize: 22 }}>h</span>
            </div>
          </div>
          <MoneyField label="Custos do projeto (opcional)" value={custos} onChange={setCustos} big={false} />
        </div>

        {ready ? (
          <React.Fragment>
            <section className="qc-result-block hero" style={{ marginTop: 8 }}>
              <p className="qc-overline">LUCRO REAL</p>
              <HeroValue value={s.lucro} prefix="R$" size="hero" color={s.lucro >= 0 ? "var(--divisao-lucro)" : "var(--color-error)"} deps={[s.lucro]} />
              <p className="qc-hero-context">Valor-hora efetivo: <strong className="tnum">{fmtBRL(s.effVH)}/h</strong></p>
            </section>

            <section className="qc-card">
              <p className="qc-card-title">Como esse projeto se divide</p>
              <DivisaoBar parts={s.parts} base={s.base} highlight="lucro" animate height={18} />
            </section>

            {s.abaixo
              ? <AlertaAbaixo alvo={alvo} sugestao={s.sugestao} onUse={() => setValor(s.sugestao)} />
              : <AlertaPositivo alvo={alvo} efetivo={s.effVH} />}

            <Seal short />
          </React.Fragment>
        ) : (
          <div className="qc-tool-empty">
            <Icon name="request_quote" size={40} />
            <p>Coloque valor e horas pra ver se o projeto te dá lucro de verdade.</p>
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { ReservaScreen, SimuladorScreen, ReservaBar, RegimePicker });
