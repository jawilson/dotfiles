alias cubelocale='cd src/Core/Cube.MasterService.Web/locale && for l in en_US es_ES fr_FR ja_JA ko_KR pt_PT ru_RU zh_CHS; do install -d ${l} ${l}_LC ${l}_Custom; done; cd -'

alias cnclean='cd ~cn; git clean -xdf \
  -e "*.user" \
  -e ".vs" \
  -e "*.*proj" \
  -e "*.cs" \
  -e "*.c" \
  -e "*.cpp" \
  -e "*.h" \
  src/; cd - > /dev/null'
