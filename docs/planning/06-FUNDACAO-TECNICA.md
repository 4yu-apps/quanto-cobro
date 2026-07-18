# Quanto Cobro? — Fundação técnica e decisões de estratégia

> As decisões de tecnologia e estratégia que o Gabriel delegou. Cada uma decidida com o
> conhecimento de mercado da pesquisa — olhando o que o concorrente faz e pegando a
> **oportunidade melhorada**. Base: [PADRÃO 4YU](../../website/PADRAO-4YU-APPS.md) + app
> Deixei Aqui (referência da casa) + [pesquisa](../research/).

---

## 1. Stack — Flutter (Android + iOS de uma base só)

**Decisão:** Flutter, seguindo o PADRÃO 4YU e o Deixei Aqui.
**Por quê:** uma base de código para Android **e** iOS (você pediu os dois), UI idêntica,
offline nativo, e é o padrão já rodando na casa. Android-first na prática — o mercado BR é
**~92,5% Android** e o público C/D vive lá; iOS entra como expansão barata (mesma base).

**Versão:** Flutter `stable 3.44.6` (via fvm, igual ao Deixei Aqui) · Dart 3.12.
**Bundle id (fixo, irreversível):** `com.fouryuapps.quantocobro`.

---

## 2. Login e conta — **NÃO haverá login. Nenhum.** (a decisão mais importante)

**Decisão:** zero cadastro, zero login social, zero conta. O app é **100% local, no aparelho**.
Nenhuma funcionalidade — nem os tools, nem o Pro, nem o backup — exige login.

**Por que (a oportunidade melhorada, direto da pesquisa):**
- **Cadastro forçado é 5,4% das ★1 do mercado** e "só usa se cadastrar o e-mail pra receber
  propaganda. Sem chance!" é queixa recorrente. Login é atrito **e** desconfiança.
- Dados de renda/imposto são **sensíveis**. Não pedir conta = argumento de privacidade e de
  marketing ("100% offline, sem cadastro"), não só ausência de feature.
- O pior app do setor (MEI Fácil, 1,92★) afunda em **"conta cancelada / login quebrado / saldo
  sumido"**. Não ter login **elimina de raiz** essa categoria inteira de ★1.
- Não precisamos de servidor: todo cálculo é local. Conta só existiria pra sincronizar — e a
  sincronização a gente resolve **sem conta** (ver §4, backup por arquivo).

> **Regra:** se algum dia sync na nuvem fizer sentido, será **opt-in explícito e anônimo**
> (sem e-mail/senha), nunca um portão na entrada. O default é e continua **sem conta**.

**"As outras ferramentas precisam de login?"** Não. Reserva, simulador, perfis, PDF, backup —
tudo funciona offline, sem conta. É coerência, não limitação.

---

## 3. Arquitetura — local-first (mirror do Deixei Aqui)

```
lib/
├── main.dart                 # boot: Firebase cedo (crash no boot), Riverpod, prefs
├── app/
│   ├── app.dart              # MaterialApp.router + tema
│   └── router.dart           # go_router (hub-and-spoke)
├── core/
│   ├── config/app_config.dart   # NOME e flags globais (fonte única — §6)
│   ├── theme/                   # tokens do Design System (cores, tipografia, "A Divisão")
│   ├── model/                   # domínio: Perfil, Regime, Custo, a Divisão
│   ├── calc/                    # MOTOR de cálculo (valor-hora, reserva, simulador) + testes
│   ├── data/                    # repositórios (Drift)
│   ├── database/                # schema Drift (SQLite local)
│   ├── settings/                # prefs (tema, moeda, telemetria opt-in)
│   ├── billing/                 # in_app_purchase (Pro) — entitlements
│   ├── platform/                # interfaces + fakes (ads, share, etc.)
│   └── common/                  # utils, formatação de moeda (intl)
└── features/
    ├── onboarding/  home/(painel)  calc/  resultado/  detalhe/
    ├── reserva/  simulador/  perfis/  config/  pro/  legal/
```

- **Estado:** Riverpod (padrão da casa).
- **Navegação:** go_router (hub-and-spoke — Painel é o hub; ver [IA](03-ARQUITETURA-DE-INFORMACAO.md)).
- **Dados:** o dado do MVP é um **documento único** (1 perfil + custos + settings). Começa
  com **repositório JSON via `shared_preferences`** atrás de uma interface (`ProfileRepository`)
  — zero code-gen, backup/export trivial (já é JSON), e sem o conflito de versão Drift×Riverpod.
  **Drift (SQLite)** entra quando o dado virar relacional/consultável (histórico de reservas em
  escala). A interface deixa a troca indolor.
- **`core/platform` com interfaces + fakes:** ads, share, in-app-review por trás de interface —
  testável sem depender do device.

---

## 4. Backup e "não perder meus dados" — sem nuvem, sem conta

**Decisão:** backup/restore por **arquivo** (exportar/importar um `.json`/`.zip` via `share_plus`),
mais o import na primeira abertura de um device novo. Nada de nuvem no MVP.

**Por quê:** "vou trocar de celular, não quero perder tudo" é **pedido recorrente** na fase 2, e
"saldo sumido / perdi dados" é ★1 pesado no setor. Resolver isso **sem exigir conta** é a
oportunidade melhorada: o usuário exporta um arquivo e guarda onde quiser (Drive, WhatsApp,
e-mail dele). Ele manda nos próprios dados — coerente com "sem login".

---

## 5. Monetização (técnico) — `in_app_purchase` + AdMob

**Decisão:** `in_app_purchase` (padrão da casa — Deixei Aqui usa, não RevenueCat) para o Pro, e
`google_mobile_ads` para o banner. Entitlements locais: `pro`, `ad_free`.
**Modelo:** freemium híbrido (vitalício + anual + mensal), núcleo grátis — detalhe em
[05 §6](05-ESCOPO-E-ROADMAP.md). Ads é secundário; o Pro é o motor.
**Regra de arquitetura anti-★1:** o **preço e o que é Pro aparecem ANTES** de o usuário investir
trabalho (o crime do TurboTax é revelar depois). O cálculo básico **nunca** fica atrás de paywall.

> Nota: o Design System cita "RevenueCat" no §8 — **superado** pela prática da casa
> (`in_app_purchase`). Registrado aqui pra não gerar conflito no build.

---

## 6. O nome numa variável só (o que você pediu) — já é padrão da casa

O PADRÃO 4YU **já resolve isso**: o nome de exibição vive **só** em
`lib/core/config/app_config.dart` (`AppConfig.appName`), nunca hardcoded. Trocar ali reflete no
app inteiro **de uma vez**. O identificador técnico (bundle `com.fouryuapps.quantocobro`) é
**fixo** e desacoplado do nome — então trocar o nome comercial depois **não quebra nada**.

```dart
abstract final class AppConfig {
  static const String appName = 'Quanto Cobro?';   // provisório — trocar aqui reflete em tudo
  static const String tagline = 'Quanto cobrar, quanto guardar, quanto sobra.';
  static const String parentBrand = '4YU';
  static const String contactEmail = 'sac@4yu.com.br';
  static const String androidPackage = 'com.fouryuapps.quantocobro';  // FIXO
  static const String webHost = '4yu.com.br';
  static const String webBasePath = '/quanto-cobro';
}
```

---

## 7. Tabelas fiscais — dado versionado, honesto e validável

**Decisão:** um módulo `core/calc/tax_tables` com as alíquotas por regime **carimbadas com ano e
fonte**, validadas na Receita antes de publicar (regra R5). O app mostra "valores base de 2025"
quando o ano vira, e posiciona todo número de imposto como **estimativa/piso**, nunca boleto.
**Por quê:** "código diferente do da Receita" é ★1 imediato; e as tabelas mudam ~1×/ano. Isolar
num módulo versionado torna a atualização anual trivial e a honestidade, estrutural.

---

## 8. Internacionalização — pronto pra pt-BR, com gancho intl

**Decisão:** `intl` para moeda/formatação desde o dia 1; strings centralizadas. **MVP em pt-BR**;
EN/ES ficam fáceis depois (FreelaCalc já faz PT/EN/ES). O **modo internacional** (freela pra
gringo, USD) é de produto, não de idioma — entra no MVP como opção de moeda/reserva.

---

## 9. Analytics, crash e LGPD

**Decisão:** Firebase (GA4 + Crashlytics), igual ao Deixei Aqui, com **telemetria opt-in**
(LGPD) lida no boot. Crashlytics sobe cedo (crash no boot é o que mais mata). Propriedade GA4
**própria do app** (não a do site) — regra 4YU. Nenhum dado sensível (renda/imposto) sai do
aparelho; telemetria é só uso/estabilidade.

---

## 10. Qualidade — o motor de cálculo tem teste

**Decisão:** o `core/calc` (valor-hora, reserva, simulador, a Divisão) é **puro e testado por
unidade**. Dinheiro errado destrói a confiança que é o nosso diferencial — então a conta é a
primeira coisa coberta por teste, com casos de borda (renda 0, horas 0 = divisão por zero,
custo > meta). Análise estática (`flutter analyze`) limpa como gate.

---

## 11. Resumo das decisões (tabela)

| Tema | Decisão | Oportunidade melhorada vs. concorrente |
|---|---|---|
| Plataforma | Flutter, Android+iOS, Android-first | mesma base 2 lojas; mercado é 92% Android |
| Login | **Nenhum** (local-first) | elimina 5% das ★1 (cadastro) + vira marketing |
| Backend | Nenhum (offline) | sem servidor = sem "saldo sumido/login quebrado" |
| Dados | Repo JSON (prefs) agora; Drift quando crescer | rápido, offline, privado, backup trivial |
| Backup | arquivo export/import, sem nuvem | resolve "trocar de celular" sem exigir conta |
| Estado/Nav | Riverpod + go_router | padrão da casa, testável |
| Pro | in_app_purchase, híbrido | preço transparente antes do trabalho (anti-TurboTax) |
| Ads | AdMob, secundário | nunca sobre número; some no Pro |
| Nome | `AppConfig.appName` (fonte única) | troca em 1 lugar; bundle fixo desacoplado |
| Fiscal | tabelas versionadas + "estimativa" | evita "diferente da Receita" (★1) |
| Analytics | Firebase GA4/Crashlytics, opt-in | LGPD; dado sensível nunca sai do device |

---

*Próximo: scaffold do app seguindo esta fundação. Cor/telas finais só depois.*
