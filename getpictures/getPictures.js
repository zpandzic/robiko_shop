// komanda za pokrecanje: node --experimental-fetch getPictures.js
const fs = require("fs");
const PHPSESSID = "PHPSESSID=vga3fkmfahpf1fp95088rmr2ie";

const pretraziSliku = (pattern) => {
  return fetch(
    "https://nuic.atit-solutions.eu/classes/tecdoc_ajax.php?load_articles=true",
    {
      headers: {
        accept: "application/json, text/javascript, */*; q=0.01",
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
        cookie: PHPSESSID,
      },
      body:
        "action=load_articles&pattern=" +
        pattern +
        "&pattern_type=10&search_show_attributes=1&search_only_on_stock=0&search_show_price=1",
      method: "POST",
    }
  )
    .then((response) => response.json())
    .then((data) => {
      const slikaObjekta = Object.values(data?.resultData || {}).find(
        (artikl) => artikl.picture
      );
      const slika = slikaObjekta ? slikaObjekta.picture : null;
      return slika;
    });
};

const ucitajPodatke = (filePath) => {
  return new Promise((resolve, reject) => {
    fs.readFile(filePath, "utf8", (err, data) => {
      if (err) {
        reject(err);
      } else {
        resolve(data ? JSON.parse(data) : {});
      }
    });
  });
};

const dohvatiSlikuPoBarkoduIKatBroju = async (barkod, katBroj) => {
  let slika = null;

  if (barkod !== katBroj && barkod.length > 8) {
    slika = await pretraziSliku(barkod);
  }

  if (!slika) {
    slika = await pretraziSliku(katBroj);
  }
  return slika;
};

const obradiCSV = (csvFilePath) => {
  const data = fs.readFileSync(csvFilePath, "utf8");

  const lines = data.split("\n");
  lines.shift();
  lines.shift();

  const artikli = {};

  lines.forEach((line) => {
    const parts = line.split(";");
    const katBroj = parts[6];
    const barkod = parts[5];
    const naziv = parts[7];

    artikli[katBroj] = { katBroj, barkod, naziv, katBroj };
  });

  return artikli;
};

const obrisiZagrade = (string) => {
  return string.split("(")[0].trim();
};

const obradiArtikle = async () => {
  const artikliCSV = obradiCSV("assets/csv/ak2-finalno.csv");
  const spremljeneSlike = await ucitajPodatke("getpictures/rezultatSlika.json");
  let index = 0;
  for (const key of Object.keys(artikliCSV)) {
    const artikl = artikliCSV[key];
    index++;
    console.log(
      index + "/" + Object.keys(artikliCSV).length,
      "katBroj:" + artikl.katBroj,
      spremljeneSlike[artikl.katBroj] && !artikl.katBroj.includes("(") ? "SKIPPED" : ""
    );

    if (spremljeneSlike[artikl.katBroj] && !artikl.katBroj.includes("(")) {
      continue;
    }
    try {
      const slika = await dohvatiSlikuPoBarkoduIKatBroju(
        artikl.barkod,
        obrisiZagrade(artikl.katBroj)
      );
      spremljeneSlike[artikl.katBroj] = {
        slika: slika ? slika : null,
        naziv: artikl.naziv,
        barkod: artikl.barkod,
        katBroj: artikl.katBroj,
      };

      fs.writeFile(
        "getpictures/rezultatSlika.json",
        JSON.stringify(spremljeneSlike, null, 2),
        "utf8",
        (err) => {}
      );
    } catch (err) {
      console.log(err);
    }
  }
};

obradiArtikle().catch(console.error);
