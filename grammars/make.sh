if [[ ! -d jing-trang ]]; then
  git clone https://github.com/relaxng/jing-trang.git
  cd jing-trang
  ./ant
  cd ..
fi
java -jar jing-trang/build/trang.jar -I rnc -O rng biblio.rnc biblio.rng
java -jar jing-trang/build/trang.jar -I rnc -O rng biblio-standoc.rnc biblio-standoc.rng
java -jar jing-trang/build/trang.jar -I rnc -O rng biblio-compile.rnc biblio-compile.rng
