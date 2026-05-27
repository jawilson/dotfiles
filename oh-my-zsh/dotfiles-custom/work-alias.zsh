alias cubelocale='cd src/Core/Cube.MasterService.Web/locale && for l in en_US es_ES fr_FR ja_JA ko_KR pt_PT ru_RU zh_CHS; do install -d ${l} ${l}_LC ${l}_Custom; done; cd -'

alias vsclean='git clean -xdf \
  -e "*.env" \
  -e "*.user" \
  -e ".vs" \
  -e "*.*proj" \
  -e "*.cs" \
  -e "*.c" \
  -e "*.cpp" \
  -e "*.h"'

alias cnclean='cd ~cn; vsclean src/; cd - > /dev/null'
