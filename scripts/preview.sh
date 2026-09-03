#!/usr/bin/env bash
# Abre o app numa janela do WSLg, no formato de CELULAR.
#
# Por que existe: `flutter run -d linux` abre a janela em 1280x720, e de
# `medium` (600dp) pra cima a casca do app troca a navbar de baixo pelo trilho
# lateral. Você acabaria julgando o layout de tablet achando que é o do
# celular. Aqui a janela nasce em 414x736 — o mesmo enquadramento das capturas
# da loja, que é o que o usuário vê.
#
#   ./scripts/preview.sh
#
# Na janela: `r` recarrega na hora (hot reload), `R` reinicia do zero, `q`
# fecha. Mexeu no código e salvou? `r` e pronto.
#
# Pré-requisito, uma vez só:  sudo apt-get install -y cmake ninja-build
#
# A pasta `linux/` é scaffold gerado, está no .gitignore e pode ser apagada a
# qualquer momento: este script a regenera.
set -euo pipefail

cd "$(dirname "$0")/.."
export PATH="$HOME/fvm/versions/stable/bin:$PATH"

for bin in cmake ninja; do
  command -v "$bin" >/dev/null || {
    echo "falta '$bin'. Rode:  sudo apt-get install -y cmake ninja-build" >&2
    exit 1
  }
done

# O scaffold do desktop não existe no repo (é ignorado). Gera na primeira vez.
#
# `flutter create` é grosseiro: além da pasta linux/, ele reescreve o
# .metadata (apagando as entradas de android e ios!), mexe no pubspec.lock e
# despeja um test/widget_test.dart de template que não compila contra este app
# e quebraria a suíte. Nada disso é o que a gente pediu, então desfazemos.
if [ ! -d linux ]; then
  echo "==> gerando o scaffold linux/ (só na primeira vez)"
  flutter create --platforms=linux . >/dev/null
  git checkout -- .metadata pubspec.lock 2>/dev/null || true
  rm -f test/widget_test.dart
  echo "==> desfeitos os efeitos colaterais do flutter create"
fi

# O tamanho da janela é hardcoded em C no runner. Troca 1280x720 por 414x736.
RUNNER=linux/runner/my_application.cc
if [ -f "$RUNNER" ] && grep -q "1280, 720" "$RUNNER"; then
  echo "==> janela em 414x736 (formato de celular)"
  sed -i 's/1280, 720/414, 736/' "$RUNNER"
fi

exec flutter run -d linux "$@"
