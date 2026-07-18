/* ============================================================
   QUANTO EU COBRO?  ·  screens-misc.jsx
   8. Perfis (Pro)  ·  9. Configurações  ·  10. Tela Pro
   ============================================================ */

function ProRow({ icon, title, sub }) {
  return (
    <div className="qc-pro-benefit">
      <span className="qc-pro-ico"><Icon name={icon} size={22} /></span>
      <div><strong>{title}</strong><small>{sub}</small></div>
    </div>
  );
}

/* ---------- 10. TELA PRO ---------- */
function ProScreen({ go, snack }) {
  return (
    <div className="qc-screen">
      <AppBar title="Quanto Cobro? Pro" onBack={() => go("painel")} />
      <div className="qc-scroll">
        <div className="qc-pro-hero">
          <span className="qc-pro-badge"><Icon name="workspace_premium" size={26} className="fill" /></span>
          <h1>Vire sua calculadora numa ferramenta de trabalho.</h1>
          <p>Compra única. Sem assinatura, sem anúncio, 100% offline.</p>
        </div>

        <section className="qc-card" style={{ display: "flex", flexDirection: "column", gap: 4 }}>
          <ProRow icon="picture_as_pdf" title="Exportar orçamento em PDF" sub="Mande um orçamento com cara de profissional" />
          <ProRow icon="switch_account" title="Vários perfis" sub="Cliente recorrente × projeto avulso × nicho" />
          <ProRow icon="tune" title="Modo avançado por regime" sub="Faixas do Simples, INSS 11/20%, deduções" />
          <ProRow icon="block" title="Remover anúncios" sub="Nada compete com o seu número" />
        </section>

        <div className="qc-pro-price">
          <span className="tnum">R$ 29,90</span>
          <small>pagamento único</small>
        </div>
        <PrimaryButton icon="lock_open" onClick={() => snack("Compra simulada — Pro desbloqueado")}>Desbloquear Pro</PrimaryButton>
        <button className="qc-btn-text" style={{ margin: "12px auto 0", display: "flex", color: "var(--color-onSurfaceVariant)" }} onClick={() => snack("Nenhuma compra encontrada")}>Restaurar compras</button>
      </div>
    </div>
  );
}

/* ---------- 8. PERFIS (Pro) ---------- */
function PerfisScreen({ go }) {
  const [sel, setSel] = useState("padrao");
  const perfis = [
    { id: "padrao", nome: "Padrão", vh: 92 },
    { id: "recorrente", nome: "Cliente recorrente", vh: 78, locked: true },
    { id: "avulso", nome: "Projeto avulso", vh: 115, locked: true },
  ];
  return (
    <div className="qc-screen">
      <AppBar title="Perfis" onBack={() => go("painel")}
        action={<button className="qc-iconbtn" onClick={() => go("pro")} aria-label="Novo perfil"><Icon name="add" size={24} /></button>} />
      <div className="qc-scroll">
        <div className="qc-perfil-list">
          {perfis.map((p) => (
            <button key={p.id} className={"qc-perfil" + (sel === p.id ? " sel" : "") + (p.locked ? " locked" : "")}
              onClick={() => (p.locked ? go("pro") : setSel(p.id))}>
              <span className="qc-radio">{sel === p.id && !p.locked && <span className="qc-radio-dot" />}</span>
              <span className="qc-perfil-name">{p.nome}{p.locked && <Icon name="lock" size={15} style={{ color: "var(--color-onSurfaceVariant)" }} />}</span>
              <span className="qc-perfil-vh tnum">{fmtBRL(p.vh)}<small>/h</small></span>
            </button>
          ))}
        </div>
        <button className="qc-pro-note" onClick={() => go("pro")}>
          <Icon name="info" size={18} />
          <span>Vários perfis é recurso <strong>Pro</strong>. Toque pra desbloquear.</span>
          <Icon name="chevron_right" size={18} />
        </button>
      </div>
    </div>
  );
}

/* ---------- 9. CONFIGURAÇÕES ---------- */
function ConfigScreen({ go, theme, onToggleTheme, onWipe, snack }) {
  const [intl, setIntl] = useState(false);
  const [confirm, setConfirm] = useState(0); // 0 idle · 1 primeira · 2 dupla

  return (
    <div className="qc-screen">
      <AppBar title="Configurações" onBack={() => go("painel")} />
      <div className="qc-scroll">
        <p className="qc-config-group">Aparência</p>
        <section className="qc-card qc-config">
          <div className="qc-config-row">
            <span><Icon name="dark_mode" size={20} />Tema</span>
            <div className="qc-seg-ctl tight">
              <button className={theme === "dark" ? "on" : ""} onClick={() => theme !== "dark" && onToggleTheme()}>Escuro</button>
              <button className={theme === "light" ? "on" : ""} onClick={() => theme !== "light" && onToggleTheme()}>Claro</button>
            </div>
          </div>
        </section>

        <p className="qc-config-group">Cálculo</p>
        <section className="qc-card qc-config">
          <div className="qc-config-row">
            <span><Icon name="payments" size={20} />Moeda</span>
            <button className="qc-config-val" onClick={() => snack("Moeda: apenas Real (R$) no MVP")}>Real (R$) <Icon name="expand_more" size={18} /></button>
          </div>
          <div className="qc-config-row">
            <span><Icon name="public" size={20} />Modo internacional</span>
            <button className={"qc-switch" + (intl ? " on" : "")} onClick={() => setIntl(!intl)} aria-label="Modo internacional"><span className="qc-switch-knob" /></button>
          </div>
          <div className="qc-config-row">
            <span><Icon name="calendar_month" size={20} />Ano das tabelas</span>
            <button className="qc-config-val" onClick={() => snack("Tabelas base de 2025")}>2025 <Icon name="expand_more" size={18} /></button>
          </div>
        </section>

        <p className="qc-config-group">Dados &amp; conta</p>
        <section className="qc-card qc-config">
          <div className="qc-config-row" role="button" onClick={() => snack("Nenhuma compra encontrada")}>
            <span><Icon name="restore" size={20} />Restaurar compras</span>
            <Icon name="chevron_right" size={18} />
          </div>
          <div className="qc-config-row danger" role="button" onClick={() => setConfirm(1)}>
            <span><Icon name="delete" size={20} />Apagar meus dados</span>
            <Icon name="chevron_right" size={18} />
          </div>
        </section>

        <button className="qc-sobre" onClick={() => snack("Quanto eu Cobro? · v1.0")}>
          <span>Sobre</span>
          <span className="qc-by4yu">by <strong>4YU</strong></span>
        </button>
      </div>

      {confirm > 0 && (
        <div className="qc-sheet-scrim qc-scrim-center" onClick={() => setConfirm(0)}>
          <div className="qc-dialog" onClick={(e) => e.stopPropagation()}>
            <Icon name="warning" size={28} style={{ color: "var(--color-error)" }} />
            <h2>{confirm === 1 ? "Apagar todos os seus dados?" : "Tem certeza mesmo?"}</h2>
            <p>{confirm === 1
              ? "Renda, custos, regime e perfis serão apagados deste aparelho. Não dá pra desfazer."
              : "Essa ação é definitiva. Você vai recomeçar do zero."}</p>
            <div className="qc-dialog-actions">
              <button className="qc-dialog-cancel" onClick={() => setConfirm(0)}>Cancelar</button>
              <button className="qc-dialog-danger" onClick={() => { if (confirm === 1) { setConfirm(2); } else { setConfirm(0); onWipe(); } }}>
                {confirm === 1 ? "Apagar" : "Apagar tudo"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

Object.assign(window, { ProScreen, PerfisScreen, ConfigScreen });
