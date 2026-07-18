/* ============================================================
   QUANTO EU COBRO?  ·  screens-calc.jsx
   3. Calculadora guiada (5 passos)  ·  11. Helper "estimar pra mim"
   ============================================================ */

/* campo numérico simples (horas) com teclado numérico */
function UnitField({ value, onChange, unit = "h/mês", error }) {
  const [focus, setFocus] = useState(false);
  return (
    <div className="qc-field">
      <div className={"qc-field-box big" + (focus ? " focus" : "") + (error ? " error" : "")}>
        <input
          className="qc-field-input tnum"
          inputMode="numeric" pattern="[0-9]*"
          value={value > 0 ? _num0.format(value) : ""} placeholder="0"
          onChange={(e) => { const d = e.target.value.replace(/\D/g, ""); onChange(d ? parseInt(d, 10) : 0); }}
          onFocus={(e) => { setFocus(true); e.target.select(); }} onBlur={() => setFocus(false)}
          aria-label={"Valor em " + unit}
        />
        <span className="qc-field-prefix" style={{ fontSize: 22 }}>{unit}</span>
      </div>
      {error && <p className="qc-field-help error"><Icon name="error" size={15} />{error}</p>}
    </div>
  );
}

/* ---------- helper "estimar pra mim" (sheet, §6.14) ---------- */
function HelperHoras({ open, onClose, onApply }) {
  const [ferias, setFerias] = useState(4);
  const [pago, setPago] = useState(0.65);
  const [feriados, setFeriados] = useState(true);
  const mes = Math.max(1, Math.round(((52 - ferias) * 40 * pago - (feriados ? 96 : 0)) / 12));

  return (
    <Sheet open={open} onClose={onClose} title="Vamos achar seu número real">
      <p className="qc-sheet-intro">Três perguntas rápidas. Quase ninguém fatura 160h/mês.</p>

      <div className="qc-helper-q">
        <p className="qc-helper-label">Quantas semanas de férias/folga você tira por ano?</p>
        <div className="qc-stepper-num">
          <button className="qc-stepbtn" onClick={() => setFerias(Math.max(0, ferias - 1))} disabled={ferias <= 0} aria-label="Menos uma semana">−</button>
          <span className="qc-stepval"><strong className="tnum">{ferias}</strong><small>{ferias === 1 ? "semana" : "semanas"}</small></span>
          <button className="qc-stepbtn" onClick={() => setFerias(Math.min(12, ferias + 1))} disabled={ferias >= 12} aria-label="Mais uma semana">+</button>
        </div>
      </div>

      <div className="qc-helper-q">
        <p className="qc-helper-label">De cada semana, quanto é trabalho PAGO?</p>
        <div className="qc-seg-ctl">
          {[[0.5, "~50%"], [0.65, "~65%"], [0.8, "~80%"]].map(([v, l]) => (
            <button key={l} className={pago === v ? "on" : ""} onClick={() => setPago(v)}>{l}</button>
          ))}
        </div>
        <p className="qc-helper-hint">O resto é prospecção, e-mail, proposta, estudo — tempo sem cliente.</p>
      </div>

      <div className="qc-helper-q">
        <p className="qc-helper-label">Conta os feriados? (~12/ano)</p>
        <div className="qc-seg-ctl">
          <button className={feriados ? "on" : ""} onClick={() => setFeriados(true)}>Sim</button>
          <button className={!feriados ? "on" : ""} onClick={() => setFeriados(false)}>Não</button>
        </div>
      </div>

      <div className="qc-helper-result">
        <span>Seu número estimado</span>
        <strong className="tnum">~{mes} h/mês</strong>
      </div>
      <PrimaryButton icon="check" onClick={() => onApply(mes)}>Usar ~{mes} h/mês</PrimaryButton>
    </Sheet>
  );
}

/* ---------- linha de custo editável (nome + valor) ---------- */
function CustoRow({ c, onChange, onLabel, onRemove, autoFocusName }) {
  const [focus, setFocus] = useState(false);
  return (
    <div className="qc-custorow">
      <Icon name="check_circle" size={20} className="fill" style={{ color: "var(--color-primary)" }} />
      {c.custom
        ? <input className="qc-custorow-nameinput" placeholder="Nome do custo" value={c.label}
            autoFocus={autoFocusName} onChange={(e) => onLabel(e.target.value)} aria-label="Nome do custo" />
        : <span className="qc-custorow-name">{c.label}</span>}
      <div className={"qc-custorow-val" + (focus ? " focus" : "")}>
        <span className="tnum">R$</span>
        <input className="tnum" inputMode="numeric" pattern="[0-9]*"
          value={c.valor > 0 ? _num0.format(c.valor) : ""} placeholder="0"
          onChange={(e) => { const d = e.target.value.replace(/\D/g, ""); onChange(d ? parseInt(d, 10) : 0); }}
          onFocus={(e) => { setFocus(true); e.target.select(); }} onBlur={() => setFocus(false)} />
      </div>
      <button className="qc-iconbtn" style={{ width: 36, height: 36 }} onClick={onRemove} aria-label={"Remover " + (c.label || "custo")}><Icon name="close" size={18} /></button>
    </div>
  );
}

/* ============================================================
   CalcScreen — orquestra os 5 passos
   ============================================================ */
function CalcScreen({ draft, setDraft, go, onFinish }) {
  const [step, setStep] = useState(1);
  const [helperOpen, setHelperOpen] = useState(false);
  const TOTAL = 5;

  const back = () => (step === 1 ? go("painel") : setStep(step - 1));
  const next = () => (step === TOTAL ? onFinish() : setStep(step + 1));
  const patch = (k, v) => setDraft({ ...draft, [k]: v });

  const addCusto = (chip) => {
    if (draft.custos.some((c) => c.id === chip.id)) return;
    patch("custos", [...draft.custos, { id: chip.id, label: chip.label, valor: chip.sugg }]);
  };
  const [focusIdx, setFocusIdx] = useState(-1);
  const addCustom = () => { setFocusIdx(draft.custos.length); patch("custos", [...draft.custos, { id: "c" + Date.now(), label: "", valor: 0, custom: true }]); };
  const usedIds = new Set(draft.custos.map((c) => c.id));
  const total = custosTotal(draft);

  const canNext =
    step === 1 ? draft.renda > 0 :
    step === 2 ? draft.horas > 0 : true;

  return (
    <div className="qc-screen">
      <div className="qc-calc-top">
        <Stepper step={step} total={TOTAL} onBack={back} />
      </div>

      <div className="qc-scroll qc-calc-body" key={step}>
        {step === 1 && (
          <div className="qc-q-block">
            <h1 className="qc-question">Quanto você quer <em>ganhar</em> por mês?</h1>
            <p className="qc-question-sub">Limpo, no bolso.</p>
            <MoneyField value={draft.renda} onChange={(v) => patch("renda", v)} autoFocus
              help="É o que você quer que sobre pra você — não o faturamento."
              error={draft.renda === 0 ? null : undefined} />
          </div>
        )}

        {step === 2 && (
          <div className="qc-q-block">
            <h1 className="qc-question">Quantas horas você realmente <em>fatura</em> por mês?</h1>
            <UnitField value={draft.horas} onChange={(v) => patch("horas", v)} unit="h/mês"
              error={draft.horas === 0 ? "Preciso de pelo menos 1 hora faturável pra fazer a conta." : null} />
            <p className="qc-field-help warn">
              <Icon name="warning" size={16} />
              Não são 160h. Tire férias, feriados e o tempo sem cliente (vendas, e-mail, estudo). Quase ninguém fatura mais que ~70%.
            </p>
            <TextButton icon="auto_awesome" onClick={() => setHelperOpen(true)}>Não sei → estimar pra mim</TextButton>
          </div>
        )}

        {step === 3 && (
          <div className="qc-q-block">
            <h1 className="qc-question">Seus custos pra trabalhar?</h1>
            <div className="qc-custos-list">
              {draft.custos.map((c, i) => (
                <CustoRow key={c.id + i} c={c} autoFocusName={i === focusIdx}
                  onChange={(v) => patch("custos", draft.custos.map((x, j) => j === i ? { ...x, valor: v } : x))}
                  onLabel={(v) => patch("custos", draft.custos.map((x, j) => j === i ? { ...x, label: v } : x))}
                  onRemove={() => patch("custos", draft.custos.filter((_, j) => j !== i))} />
              ))}
            </div>

            <button className="qc-add-custo" onClick={addCustom}>
              <Icon name="add" size={20} /><span>Adicionar um custo seu</span>
            </button>

            <p className="qc-naoesqueca">Não esqueça:</p>
            <div className="qc-chips">
              {COST_CHIPS.filter((c) => !usedIds.has(c.id)).slice(0, 6).map((c) => (
                <button key={c.id} className="qc-chip" onClick={() => addCusto(c)}>
                  <Icon name={c.icon} size={18} /><span>{c.label}</span><Icon name="add" size={16} />
                </button>
              ))}
            </div>

            <div className="qc-custos-total">
              <span>Total</span>
              <strong className="tnum">{fmtBRL(total)}<small>/mês</small></strong>
            </div>
          </div>
        )}

        {step === 4 && (
          <div className="qc-q-block">
            <h1 className="qc-question">Como você recebe hoje?</h1>
            <div className="qc-regime-list">
              {Object.values(REGIMES).map((r) => (
                <button key={r.id} className={"qc-regime-opt" + (draft.regime === r.id ? " sel" : "")} onClick={() => patch("regime", r.id)}>
                  <span className="qc-radio">{draft.regime === r.id && <span className="qc-radio-dot" />}</span>
                  <span className="qc-regime-text">
                    <strong>{r.label}</strong>
                    <small>{r.sub}</small>
                  </span>
                </button>
              ))}
            </div>
          </div>
        )}

        {step === 5 && (
          <div className="qc-q-block">
            <h1 className="qc-question">Quer provisionar férias e 13º?</h1>
            <p className="qc-question-sub">Autônomo não ganha de graça — guarde pra não trabalhar 12 meses sem descanso pago.</p>
            <div className="qc-bigchoice">
              <button className={"qc-choice" + (draft.provisaoOn ? " sel" : "")} onClick={() => setDraft({ ...draft, provisaoOn: true })}>
                <Icon name="beach_access" size={26} />
                <span><strong>Sim, reservar 1 mês/ano</strong><small>+ {fmtBRL(draft.provisao)}/mês no cálculo</small></span>
              </button>
              <button className={"qc-choice" + (!draft.provisaoOn ? " sel" : "")} onClick={() => setDraft({ ...draft, provisaoOn: false })}>
                <Icon name="schedule" size={26} />
                <span><strong>Agora não</strong><small>posso ajustar depois</small></span>
              </button>
            </div>
          </div>
        )}
      </div>

      <div className="qc-calc-footer">
        <PrimaryButton onClick={next} disabled={!canNext} icon={step === TOTAL ? "check" : undefined}>
          {step === TOTAL ? "Ver resultado" : "Continuar"}
        </PrimaryButton>
      </div>

      <HelperHoras open={helperOpen} onClose={() => setHelperOpen(false)}
        onApply={(h) => { patch("horas", h); setHelperOpen(false); }} />
    </div>
  );
}

Object.assign(window, { CalcScreen, HelperHoras, UnitField });
