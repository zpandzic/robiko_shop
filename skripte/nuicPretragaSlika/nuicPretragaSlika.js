// komanda za pokrecanje: node --experimental-fetch getPictures.js
const fs = require("fs");
const PHPSESSID = "PHPSESSID=gmsn7qs72iblpmir7lcnm3gnfq";

//vec ucitane slike getpictures/rezultatSlikaNuic.json
const slike_visoka_zalihe =
  "getpictures/nuicPretragaSlika/slike_visoka_zalihe.json";

//postaviti i funkciju obrade
const pathCSV = "assets/csv/Visoka_zalihe_18_04_2024.csv";

const pretraziNuica = (pattern) => {
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

const ucitajJSON = (filePath) => {
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
    slika = await pretraziNuica(barkod);
  }

  if (!slika) {
    slika = await pretraziNuica(katBroj);
  }
  return slika;
};

const obrisiZagrade = (string) => {
  return string.split("(")[0].trim();
};

const ucitajCSVVisokaZalihe = (csvFilePath) => {
  const data = fs.readFileSync(csvFilePath, "utf8");

  const lines = data.split("\n");
  const firstLine = lines.shift().split(";"); //Rbr.;Šifra robe;Barcode;KatBroj;Naziv robe;JMJ;Stanje;MPC

  const artikli = {};

  const katBrojIndex = firstLine.indexOf("KatBroj");
  const barkodIndex = firstLine.indexOf("Barcode");
  const nazivIndex = firstLine.indexOf("Naziv robe");
  const sifraIndex = firstLine.indexOf("Šifra robe");
  const jmjIndex = firstLine.indexOf("JMJ");
  const stanjeIndex = firstLine.indexOf("Stanje");
  const mpcIndex = firstLine.indexOf("MPC");

  lines.forEach((line) => {
    const parts = line.split(";");

    const katBroj = parts[katBrojIndex];
    const barkod = parts[barkodIndex];
    const naziv = parts[nazivIndex];
    const sifra = parts[sifraIndex];
    const jmj = parts[jmjIndex];
    const stanje = parts[stanjeIndex];
    const mpc = parts[mpcIndex];

    artikli[katBroj] = { katBroj, barkod, naziv, katBroj };
  });

  return artikli;
};

const spremiJson = (filePath, data) => {
  try {
    fs.writeFile(filePath, JSON.stringify(data, null, 2), "utf8", (err) => {});
  } catch (err) {
    console.log(err);
  }
};
const napraviZaImport = async (maxParalelno = 3) => {
  const podaciCSV = await ucitajCSVVisokaZalihe(pathCSV);
  //   console.log(Object.keys(podaci).length);
  const spremljeneSlike = await ucitajJSON(slike_visoka_zalihe);

  let index = 0;
  let obrade = [];
  let totalCalls = 0;

  const keys = Object.keys(podaciCSV);

  for (const key of keys) {
    const artikl = podaciCSV[key];
    index++;
    console.log(
      index + "/" + keys.length,
      "katBroj:" + artikl.katBroj,
      spremljeneSlike[artikl.katBroj] ? "----SKIPPED" : ""
    );

    if (spremljeneSlike[artikl.katBroj] !== undefined) {
      continue;
    }

    obrade.push(
      dohvatiSlikuPoBarkoduIKatBroju(
        artikl.barkod,
        obrisiZagrade(artikl.katBroj)
      )
        .then((slika) => {
          spremljeneSlike[artikl.katBroj] = slika ? slika : null;
        })
        .catch((err) =>
          console.log(
            err,
            "Neuspjesno dohvacanje slike za artikl: ",
            artikl.katBroj
          )
        )
    );

    totalCalls++;

    if (obrade.length >= maxParalelno || index === keys.length) {
      await Promise.all(obrade).catch((err) =>
        console.log(err, "problem kod Promise.all", err)
      );
      obrade = [];
    }

    if (totalCalls % 10 === 0) {
      console.log("Total calls to server: ", totalCalls);
    }

    if (totalCalls % 20 === 0) {
      spremiJson(slike_visoka_zalihe, spremljeneSlike);
    }
  }

  console.log("Total calls to server: ", totalCalls);

  spremiJson(slike_visoka_zalihe, spremljeneSlike);
};

napraviZaImport();
