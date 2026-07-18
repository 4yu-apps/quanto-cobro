/* ============================================================
   QUANTO EU COBRO?  ·  components.jsx
   Componentes compartilhados do sistema "A Divisão".
   ============================================================ */
const { useState, useEffect, useRef, useMemo } = React;

/* ---------- helpers de moeda / número (intl, tabular) ---------- */
const _brl0 = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 });
const _brl2 = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", minimumFractionDigits: 2, maximumFractionDigits: 2 });
const _num0 = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 });
function fmtBRL(v, cents = false) {return (cents ? _brl2 : _brl0).format(Math.round(cents ? v * 100 : v) / (cents ? 100 : 1));}
function prefersReduced() {return window.__qcReduceMotion || window.matchMedia("(prefers-reduced-motion: reduce)").matches;}
function fmtBRLk(v) {// "R$ 10,1k"
  if (v >= 1000) return "R$ " + (v / 1000).toLocaleString("pt-BR", { minimumFractionDigits: 1, maximumFractionDigits: 1 }) + "k";
  return fmtBRL(v);
}
function pct(part, total) {return total > 0 ? Math.round(part / total * 100) : 0;}

/* ---------- ícone Material Symbols Rounded ---------- */
function Icon({ name, size = 24, fill = false, className = "", style = {} }) {
  return (
    <span
      className={"material-symbols-rounded" + (fill ? " fill" : "") + (className ? " " + className : "")}
      style={{ fontSize: size, ...style }}
      aria-hidden="true">
      {name}</span>);

}

/* ---------- count-up para o número-herói (motion.countUp 600ms) ---------- */
function useCountUp(target, deps = [], { duration = 600, enabled = true } = {}) {
  const [val, setVal] = useState(enabled ? 0 : target);
  const raf = useRef(0);
  useEffect(() => {
    if (!enabled || prefersReduced()) {setVal(target);return;}
    const from = 0,start = performance.now();
    const tick = (now) => {
      const t = Math.min(1, (now - start) / duration);
      const e = 1 - Math.pow(1 - t, 3); // ease-out cubic
      setVal(from + (target - from) * e);
      if (t < 1) raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf.current);
  }, deps); // eslint-disable-line
  return val;
}

/* ============================================================
   A DIVISÃO  ·  a barra-assinatura (§6.2)
   parts: { lucro, reserva, custo } em R$  ·  base = 100%
   highlight: 'lucro' | 'reserva' | 'custo' | null
   ============================================================ */
const DIVISAO_META = {
  lucro: { label: "Lucro", sub: "é seu", icon: "account_balance_wallet", varc: "--divisao-lucro" },
  reserva: { label: "Reserva", sub: "imposto", icon: "savings", varc: "--divisao-reserva" },
  custo: { label: "Custos", sub: "te mantêm", icon: "build", varc: "--divisao-custo" }
};

function DivisaoBar({ parts, base, highlight = null, animate = true, showLegend = true, height = 18 }) {
  const total = base ?? parts.lucro + parts.reserva + parts.custo;
  const order = ["lucro", "reserva", "custo"];
  const [shown, setShown] = useState(!animate);
  useEffect(() => {
    if (!animate) return;
    if (prefersReduced()) {setShown(true);return;}
    const id = requestAnimationFrame(() => requestAnimationFrame(() => setShown(true)));
    return () => cancelAnimationFrame(id);
  }, [animate, parts.lucro, parts.reserva, parts.custo, base]);

  return (
    <div className="qc-divisao">
      <div className="qc-divisao-track" style={{ height }} role="img"
      aria-label={order.map((k) => `${DIVISAO_META[k].label} ${fmtBRL(parts[k])}, ${pct(parts[k], total)} por cento`).join(". ")}>
        {order.map((k) => {
          const w = shown ? pct(parts[k], total) : 0;
          const dim = highlight && highlight !== k;
          return (
            <div key={k} className={"qc-seg qc-seg-" + k + (dim ? " dim" : "")}
            style={{ width: w + "%", background: `var(${DIVISAO_META[k].varc})` }} />);

        })}
      </div>
      {showLegend &&
      <ul className="qc-legend">
          {order.map((k) => {
          const m = DIVISAO_META[k];
          const hot = highlight === k;
          return (
            <li key={k} className={"qc-legend-item" + (hot ? " hot" : "")}>
                <span className={"qc-dot qc-dot-" + k} style={{ background: `var(${m.varc})` }} />
                <span className="qc-legend-label">
                  <Icon name={m.icon} size={15} style={{ color: `var(${m.varc})`, transform: "translateY(2px)" }} />
                  <span>{m.label}</span>
                </span>
                <span className="qc-legend-val tnum">{fmtBRL(parts[k])}</span>
                <span className="qc-legend-pct tnum">{pct(parts[k], total)}%</span>
              </li>);

        })}
        </ul>
      }
    </div>);

}

/* ============================================================
   HERO VALUE  ·  o número é o herói (§4.2)
   ============================================================ */
function HeroValue({ value, suffix = "", prefix = "R$", size = "hero", color = "var(--color-primary)", countUp = true, cents = false, deps = [] }) {
  const animated = useCountUp(value, deps.length ? deps : [value], { enabled: countUp });
  const v = countUp ? animated : value;
  const sizes = { hero: "var(--value-hero)", xl: "var(--value-xl)", lg: "var(--value-lg)", md: "var(--value-md)" };
  return (
    <div className="qc-hero tnum" style={{ fontSize: sizes[size], color }}>
      {prefix && <span className="qc-hero-prefix">{prefix}</span>}
      <span className="qc-hero-num">{cents ? _num0.format(0) : _num0.format(Math.round(v))}{cents ? "" : ""}</span>
      {suffix && <span className="qc-hero-suffix">{suffix}</span>}
    </div>);

}

/* ============================================================
   SELO de estimativa  ·  onipresente, calmo (§6.11)
   ============================================================ */
function Seal({ short = false }) {
  return (
    <div className="qc-seal">
      <Icon name="info" size={16} />
      <span>{short ? "Estimativa pra te ajudar a decidir." : "Estimativa de planejamento — não é consultoria fiscal."}</span>
    </div>);

}

/* ---------- faixa "tabela desatualizada" (§2.4) ---------- */
function StaleBanner({ year = 2025 }) {
  return (
    <div className="qc-stale">
      <Icon name="update" size={16} />
      <span>Valores base de {year} — confirme as alíquotas atuais.</span>
    </div>);

}

/* ============================================================
   BOTÕES
   ============================================================ */
function PrimaryButton({ children, onClick, icon, disabled = false, full = true, style = {} }) {
  return (
    <button className={"qc-btn-primary" + (full ? " full" : "")} onClick={onClick} disabled={disabled} style={style}>
      {icon && <Icon name={icon} size={22} />}
      <span>{children}</span>
    </button>);

}
function TextButton({ children, onClick, icon, color = "var(--color-primary)", style = {} }) {
  return (
    <button className="qc-btn-text" onClick={onClick} style={{ color, ...style }}>
      {icon && <Icon name={icon} size={18} />}
      <span>{children}</span>
    </button>);

}

/* ---------- dois cards-ação do Painel (§6.3) ---------- */
function ToolActionCard({ icon, label, onClick }) {
  return (
    <button className="qc-toolcard" onClick={onClick}>
      <Icon name={icon} size={28} />
      <span>{label}</span>
    </button>);

}

/* ============================================================
   CAMPO DE VALOR MONETÁRIO  ·  teclado numérico, R$ ao vivo (§6.5)
   value em número (R$). onChange(número).
   ============================================================ */
function MoneyField({ value, onChange, label, help, helpType = "info", error, autoFocus = false, big = true }) {
  const ref = useRef(null);
  const [focus, setFocus] = useState(false);
  const display = value > 0 ? _num0.format(value) : "";
  function handle(e) {
    const digits = e.target.value.replace(/\D/g, "");
    onChange(digits ? parseInt(digits, 10) : 0);
  }
  return (
    <div className="qc-field">
      {label && <label className="qc-field-label">{label}</label>}
      <div className={"qc-field-box" + (focus ? " focus" : "") + (error ? " error" : "") + (big ? " big" : "")}>
        <span className="qc-field-prefix tnum">R$</span>
        <input
          ref={ref}
          className="qc-field-input tnum"
          inputMode="numeric"
          pattern="[0-9]*"
          value={display}
          placeholder="0"
          autoFocus={autoFocus}
          onChange={handle}
          onFocus={(e) => {setFocus(true);e.target.select();}}
          onBlur={() => setFocus(false)}
          aria-label={label} />
        
      </div>
      {error ?
      <p className="qc-field-help error"><Icon name="error" size={15} />{error}</p> :
      help && <p className={"qc-field-help " + helpType}>
            <Icon name={helpType === "warn" ? "warning" : "info"} size={15} />{help}
          </p>}
    </div>);

}

/* ============================================================
   STEPPER de progresso (§6.6)
   ============================================================ */
function Stepper({ step, total, onBack }) {
  return (
    <div className="qc-stepper">
      <button className="qc-iconbtn" onClick={onBack} aria-label="Voltar"><Icon name="arrow_back" size={24} /></button>
      <span className="qc-step-label">Passo {step} de {total}</span>
      <div className="qc-dots">
        {Array.from({ length: total }).map((_, i) =>
        <span key={i} className={"qc-stepdot" + (i < step ? " on" : "")} />
        )}
      </div>
    </div>);

}

/* ============================================================
   APP BAR (header das telas-satélite)
   ============================================================ */
function AppBar({ title, onBack, action }) {
  return (
    <header className="qc-appbar">
      {onBack ?
      <button className="qc-iconbtn" onClick={onBack} aria-label="Voltar"><Icon name="arrow_back" size={24} /></button> :
      <span style={{ width: 40 }} />}
      <h1 className="qc-appbar-title">{title}</h1>
      <span className="qc-appbar-action">{action || <span style={{ width: 40 }} />}</span>
    </header>);

}

/* ============================================================
   AVISO "abaixo do alvo" — âmbar calmo (§6.12)
   ============================================================ */
function AlertaAbaixo({ alvo, sugestao, onUse }) {
  return (
    <div className="qc-alerta" role="status">
      <Icon name="trending_down" size={22} />
      <div className="qc-alerta-body">
        <p>Abaixo do seu alvo (<span className="tnum">{fmtBRL(alvo)}</span>/h). Cobre <span className="tnum">~{fmtBRL(sugestao)}</span> pra manter seu lucro.</p>
        {onUse && <button className="qc-alerta-cta" onClick={onUse}>Usar {fmtBRL(sugestao)}</button>}
      </div>
    </div>);

}

/* ---------- aviso "no azul" — reforço positivo, verde calmo ---------- */
function AlertaPositivo({ alvo, efetivo }) {
  const acima = efetivo - alvo;
  return (
    <div className="qc-positivo" role="status">
      <Icon name="trending_up" size={22} />
      <div className="qc-positivo-body">
        <p><strong>Tá no azul.</strong> Esse projeto rende <span className="tnum">{fmtBRL(efetivo)}</span>/h — {acima > 0 ? <span>R$ {acima} acima</span> : "no nível"} do seu alvo (<span className="tnum">{fmtBRL(alvo)}</span>/h). Pode fechar tranquilo.</p>
      </div>
    </div>);

}

/* ---------- banner de publicidade (§6.18) ---------- */
function AdBanner() {
  return (
    <div className="qc-ad" aria-label="Publicidade">
      <span className="qc-ad-tag">Publicidade</span>
      <div className="qc-ad-slot">
        <Icon name="ad_units" size={20} />
        <span>espaço de anúncio · banner 320×50</span>
      </div>
    </div>);

}

/* ---------- bottom sheet ---------- */
function Sheet({ open, onClose, children, title }) {
  if (!open) return null;
  return (
    <div className="qc-sheet-scrim" onClick={onClose}>
      <div className="qc-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="qc-sheet-grab" />
        {title && <div className="qc-sheet-head"><h2>{title}</h2><button className="qc-iconbtn" onClick={onClose} aria-label="Fechar"><Icon name="close" size={22} /></button></div>}
        {children}
      </div>
    </div>);

}

/* ---------- snackbar ---------- */
function Snackbar({ msg, actionLabel, onAction }) {
  if (!msg) return null;
  return (
    <div className="qc-snackbar">
      <span>{msg}</span>
      {actionLabel && <button onClick={onAction}>{actionLabel}</button>}
    </div>);

}

/* ---------- expõe ao escopo global p/ os outros arquivos babel ---------- */
Object.assign(window, {
  React, useState, useEffect, useRef, useMemo,
  fmtBRL, fmtBRLk, pct, _num0, prefersReduced,
  Icon, useCountUp, DivisaoBar, DIVISAO_META, HeroValue, Seal, StaleBanner,
  PrimaryButton, TextButton, ToolActionCard, MoneyField, Stepper, AppBar,
  AlertaAbaixo, AlertaPositivo, AdBanner, Sheet, Snackbar
});