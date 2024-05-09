echo "Updating submodules..."

#rm -f basicdoc-models/grammars/basicdoc.rng
#git submodule update

#cd basicdoc-models/grammars
#git checkout main && git pull
#cd ../..
cp basicdoc-models/grammars/basicdoc.rnc .

if [[ ! -d jing-trang ]]; then
  git clone https://github.com/relaxng/jing-trang.git
  cd jing-trang
  ./ant
  cd ..
fi
java -jar jing-trang/build/trang.jar -I rnc -O rng biblio.rnc biblio.rng
java -jar jing-trang/build/trang.jar -I rnc -O rng biblio-standoc.rnc biblio-standoc.rng
java -jar jing-trang/build/trang.jar -I rnc -O rng biblio-compile.rnc biblio-compile.rng
