/* ============================================================
   QUANTO EU COBRO?  ·  screens-result.jsx
   4. Resultado  ·  5. Detalhamento "como cheguei"
   ============================================================ */

function ResultadoScreen({ profile, comp, go, onSave, onPro }) {
  const div = divisaoFromProfile(profile, comp);
  const reservaPorReceb = Math.round(comp.faturamento * comp.rate);
  return (
    <div className="qc-screen">
      <AppBar title="Seu resultado" onBack={() => go("painel")}
        action={<button className="qc-pdf-btn" onClick={onPro}><Icon name="picture_as_pdf" size={18} />PDF<span className="qc-pro-pill">Pro</span></button>} />

      <div className="qc-scroll">
        {/* BLOCO 1 — herói único: COBRE POR HORA */}
        <section className="qc-result-hero">
          <p className="qc-overline">COBRE POR HORA</p>
          <HeroValue value={comp.valorHora} suffix="/hora" deps={[comp.valorHora]} />
          <p className="qc-equiv tnum">≈ {fmtBRL(comp.valorDia)}/dia · {fmtBRLk(comp.faturamento)}/mês faturados</p>
        </section>

        {/* BLOCO 2+3 — respostas de apoio, calmas e equivalentes entre si */}
        <div className="qc-result-stats">
          <div className="qc-stat">
            <p className="qc-stat-label"><Icon name="savings" size={15} style={{ color: "var(--divisao-reserva)" }} />RESERVE</p>
            <p className="qc-stat-num tnum" style={{ color: "var(--divisao-reserva)" }}>{comp.reservaPct}%</p>
            <p className="qc-stat-sub tnum">≈ {fmtBRL(reservaPorReceb)}/mês</p>
          </div>
          <div className="qc-stat">
            <p className="qc-stat-label"><Icon name="account_balance_wallet" size={15} style={{ color: "var(--divisao-lucro)" }} />LUCRO REAL</p>
            <p className="qc-stat-num tnum" style={{ color: "var(--divisao-lucro)" }}>{fmtBRL(comp.lucro)}</p>
            <p className="qc-stat-sub">limpos/mês</p>
          </div>
        </div>

        {/* A DIVISÃO preenchendo */}
        <section className="qc-card">
          <p className="qc-card-title">Como esse faturamento se divide</p>
          <DivisaoBar parts={div.parts} base={div.base} highlight="lucro" animate height={20} />
        </section>

        <div className="qc-result-actions">
          <TextButton icon="expand_more" onClick={() => go("detalhe")}>ver detalhamento</TextButton>
          <PrimaryButton icon="bookmark" onClick={onSave}>Salvar este perfil</PrimaryButton>
        </div>

        <Seal />
      </div>
    </div>
  );
}

/* ---------- valor editável inline (detalhamento) ---------- */
function InlineMoney({ value, onChange, prefix = "R$" }) {
  const [focus, setFocus] = useState(false);
  return (
    <span className={"qc-inline-money" + (focus ? " focus" : "")}>
      <span className="tnum">{prefix}</span>
      <input className="tnum" inputMode="numeric" pattern="[0-9]*"
        value={value > 0 ? _num0.format(value) : ""} placeholder="0"
        onChange={(e) => { const d = e.target.value.replace(/\D/g, ""); onChange(d ? parseInt(d, 10) : 0); }}
        onFocus={(e) => { setFocus(true); e.target.select(); }} onBlur={() => setFocus(false)} />
    </span>
  );
}

function DetalheScreen({ profile, setProfile, comp, go }) {
  const patch = (k, v) => setProfile({ ...profile, [k]: v });
  return (
    <div className="qc-screen">
      <AppBar title="Como cheguei nesse número" onBack={() => go("painel")} />
      <div className="qc-scroll">
        <p className="qc-detalhe-hint"><Icon name="edit" size={16} />Toque em qualquer valor pra editar — o resultado recalcula na hora.</p>

        <section className="qc-card qc-detalhe">
          <div className="qc-detalhe-row">
            <span>Renda desejada</span>
            <InlineMoney value={profile.renda} onChange={(v) => patch("renda", v)} />
          </div>
          <div className="qc-detalhe-row">
            <span>+ Custos fixos</span>
            <button className="qc-detalhe-link" onClick={() => go("calc")}>
              <span className="tnum">{fmtBRL(comp.custos)}</span><Icon name="chevron_right" size={18} />
            </button>
          </div>
          <div className="qc-detalhe-row">
            <span>+ Provisão férias/13º</span>
            {profile.provisaoOn
              ? <InlineMoney value={profile.provisao} onChange={(v) => patch("provisao", v)} />
              : <button className="qc-detalhe-link" onClick={() => patch("provisaoOn", true)}><span style={{ color: "var(--color-onSurfaceVariant)" }}>desligado</span></button>}
          </div>
          <div className="qc-detalhe-row muted">
            <span>+ Imposto estimado <em>({comp.reservaPct}%)</em></span>
            <span className="tnum">{fmtBRL(comp.imposto)}</span>
          </div>

          <div className="qc-detalhe-sum">
            <span>= Preciso faturar</span>
            <span className="tnum">{fmtBRL(comp.faturamento)}</span>
          </div>

          <div className="qc-detalhe-row">
            <span>÷ Horas faturáveis</span>
            <span className="qc-inline-units">
              <input className="tnum" inputMode="numeric" pattern="[0-9]*"
                value={profile.horas > 0 ? _num0.format(profile.horas) : ""}
                onChange={(e) => { const d = e.target.value.replace(/\D/g, ""); patch("horas", d ? parseInt(d, 10) : 0); }}
                onFocus={(e) => e.target.select()} />
              <span>h</span>
            </span>
          </div>

          <div className="qc-detalhe-final">
            <span>= Valor-hora</span>
            <span className="qc-detalhe-final-val tnum">{fmtBRL(comp.valorHora)}<small>/h</small></span>
          </div>
        </section>

        <Seal />
      </div>
    </div>
  );
}

Object.assign(window, { ResultadoScreen, DetalheScreen, InlineMoney });
