/* ============================================================
   QUANTO EU COBRO?  ·  screens-painel.jsx
   1. Painel (com cálculo)  ·  2. Painel — estado vazio
   ============================================================ */

function PainelScreen({ profile, comp, go, snack, showAd = true }) {
  const div = divisaoFromProfile(profile, comp);
  const regime = REGIMES[profile.regime];
  return (
    <div className="qc-screen">
      <header className="qc-home-bar">
        <div className="qc-wordmark">Quanto Cobro<span className="qc-q">?</span></div>
        <button className="qc-iconbtn" aria-label="Configurações" onClick={() => go("config")}><Icon name="settings" size={24} /></button>
      </header>

      <div className="qc-scroll">
        {/* CARD-HERÓI */}
        <section className="qc-card qc-hero-card">
          <p className="qc-overline">SEU VALOR-HORA</p>
          <HeroValue value={comp.valorHora} suffix="/hora" deps={[comp.valorHora]} />
          <p className="qc-hero-context">pra ganhar <strong className="tnum">{fmtBRL(profile.renda)}</strong>/mês limpos</p>

          <div className="qc-divisao-glance">
            <DivisaoBar parts={div.parts} base={div.base} animate={true} height={16} />
          </div>

          <TextButton icon="receipt_long" onClick={() => go("detalhe")} style={{ marginTop: 4 }}>ver como cheguei aqui</TextButton>
        </section>

        {/* DOIS TOOLS RECORRENTES */}
        <div className="qc-tool-row">
          <ToolActionCard icon="payments" label="Recebi um pagamento" onClick={() => go("reserva")} />
          <ToolActionCard icon="request_quote" label="Vou orçar um projeto" onClick={() => go("simulador")} />
        </div>

        {/* RESUMO RESERVA + LUCRO */}
        <section className="qc-card qc-summary">
          <div className="qc-summary-row">
            <div>
              <p className="qc-overline">DE CADA PAGAMENTO, RESERVE</p>
              <p className="qc-summary-big tnum" style={{ color: "var(--divisao-reserva)" }}>~{comp.reservaPct}%</p>
            </div>
            <span className="qc-regime-chip"><Icon name="savings" size={16} />regime: {regime.tag}</span>
          </div>
          <div className="qc-hairline" />
          <div className="qc-summary-mini">
            <div>
              <p className="qc-mini-label">Lucro real estimado</p>
              <p className="qc-mini-val tnum" style={{ color: "var(--divisao-lucro)" }}>{fmtBRL(comp.lucro)}<span>/mês</span></p>
            </div>
            <div>
              <p className="qc-mini-label">Custos cadastrados</p>
              <p className="qc-mini-val tnum">{fmtBRL(comp.custos)}<span>/mês</span></p>
            </div>
          </div>
        </section>

        <div style={{ marginTop: 4 }}>
          <Seal />
        </div>

        <PrimaryButton icon="calculate" onClick={() => go("calc")} style={{ marginTop: 16 }}>Recalcular valor-hora</PrimaryButton>

        {/* PUBLICIDADE — só no rodapé do Painel, nunca sobre número */}
        {showAd && (
          <div style={{ marginTop: 20 }}>
            <AdBanner />
          </div>
        )}
      </div>
    </div>
  );
}

/* ---------- Painel — estado vazio (§5.8 / §6.16) ---------- */
function VazioScreen({ go }) {
  return (
    <div className="qc-screen">
      <header className="qc-home-bar">
        <div className="qc-wordmark">Quanto Cobro<span className="qc-q">?</span></div>
        <button className="qc-iconbtn" aria-label="Configurações" onClick={() => go("config")}><Icon name="settings" size={24} /></button>
      </header>

      <div className="qc-scroll qc-vazio">
        <div className="qc-vazio-art" aria-hidden="true">
          <div className="qc-coin">
            <span className="material-symbols-rounded" style={{ fontSize: 64, color: "var(--color-primary)" }}>savings</span>
          </div>
        </div>
        <h1 className="qc-vazio-title">Você provavelmente cobra menos do que deveria.</h1>
        <p className="qc-vazio-sub">Descubra seu valor-hora justo em 5 perguntas.</p>
        <PrimaryButton onClick={() => go("calc")} style={{ marginTop: 8 }}>Começar</PrimaryButton>
        <p className="qc-vazio-trust"><Icon name="lock" size={16} />Leva 2 minutos · 100% offline</p>
      </div>
    </div>
  );
}

Object.assign(window, { PainelScreen, VazioScreen });
