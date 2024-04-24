// komanda za pokrecanje: node --experimental-fetch getPictures.js
const fs = require("fs");
const PHPSESSID = "PHPSESSID=6kgosvckg1b3mdh4qlvm4lsr9g";

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

const obradiCSVAk2 = (csvFilePath) => {
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

const obradiCSVNuic = (csvFilePath) => {
  const data = fs.readFileSync(csvFilePath, "utf8");

  let lines = data.split("\n");
  lines.shift();

  // Ograniči na prvih 100 linija (nakon uklanjanja zaglavlja)
  // lines = lines.slice(0, 5000);

  const artikli = {};

  lines.forEach((line) => {
    const parts = line.split(";");

    const katBroj = parts[0];
    const barkod = parts[1];

    artikli[katBroj] = { katBroj, barkod };
  });

  return artikli;
};

const obrisiZagrade = (string) => {
  return string.split("(")[0].trim();
};

// const nuicBaseUrl = "https://digital-assets.tecalliance.services/images/400/";

const obradiArtikle = async (maxParalelno = 2) => {
  console.time("procesPretrazivanja");

  const artikliCSV = obradiCSVNuic("assets/csv/nuic.csv");
  const spremljeneSlike = await ucitajPodatke(
    "getpictures/rezultatSlikaNuic.json"
  );

  let index = 0;
  let obrade = [];
  let totalCalls = 0;

  const keys = Object.keys(artikliCSV);

  for (const key of keys) {
    const artikl = artikliCSV[key];
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
          spremljeneSlike[artikl.katBroj] = slika
            ? slika.replace(
                "https://digital-assets.tecalliance.services/images/400/",
                ""
              )
            : null;
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
      try {
        fs.writeFile(
          "getpictures/rezultatSlikaNuic.json",
          JSON.stringify(spremljeneSlike, null, 2),
          "utf8",
          (err) => {}
        );
        console.log("Saved to file");
      } catch (err) {
        console.log(err);
      }
    }
  }

  console.log("Total calls to server: ", totalCalls);
  try {
    fs.writeFile(
      "getpictures/rezultatSlikaNuic.json",
      JSON.stringify(spremljeneSlike, null, 2),
      "utf8",
      (err) => {}
    );
  } catch (err) {
    console.log(err);
  }
  console.timeEnd("procesPretrazivanja");
};

// obradiArtikle(1).catch(console.error); // Primjer kako pozvati s parametrom za 3 paralelna poziva

// s 3
// Total calls to server:  155
// procesPretrazivanja: 1:05.135 (m:ss.mmm)

// s 6
// Total calls to server:  155
// procesPretrazivanja: 39.475s

const napraviZaImport = async () => {
  const spremljeneSlike = await ucitajPodatke(
    "getpictures/rezultatSlikaNuic.json"
  );

  const artikli = {};

  const listingIdJson = await ucitajPodatke("getpictures/katbroj_id.json");
  const artikliAk2 = obradiCSVAk2("assets/csv/ak2-finalno.csv");

  Object.keys(artikliAk2).forEach((key) => {
    const artikl = artikliAk2[key];

    let slikaUrl = spremljeneSlike[artikl.katBroj];

    if (slikaUrl && !spremljeneSlike[artikl.katBroj]?.includes("https://")) {
      slikaUrl = `https://digital-assets.tecalliance.services/images/400/${slikaUrl}`;
    }

    const newKey = key.replace(/[$#.\[\]\/]/g, "_");

    if (newKey.length) {
      artikli[newKey] = {
        katBroj: artikl.katBroj,
        barkod: artikl.barkod,
        slika: slikaUrl,
        listingId: listingIdJson[artikl.katBroj]?.listingId ?? null,
        price: listingIdJson[artikl.katBroj]?.price ?? null,
      };
    }
  });

  const artikliNuic = obradiCSVNuic("assets/csv/nuic.csv");

  Object.keys(artikliNuic).forEach((key) => {

    const artikl = artikliNuic[key];

    let slikaUrl = spremljeneSlike[artikl.katBroj];

    if (slikaUrl &&!spremljeneSlike[artikl.katBroj]?.includes("https://")) {
      slikaUrl = `https://digital-assets.tecalliance.services/images/400/${slikaUrl}`;
    }

    const newKey = key.replace(/[$#.\[\]\/]/g, '_');

    if(newKey.length){
      artikli[newKey] ={
        katBroj: artikl.katBroj,
        barkod: artikl.barkod,
        slika: slikaUrl,
        listingId: listingIdJson[artikl.katBroj]?.listingId ?? null,
        price: listingIdJson[artikl.katBroj]?.price ?? null,
      };
    }
  });

  fs.writeFile(
    "getpictures/zaimport.json",
    JSON.stringify(artikli, null, 2),
    "utf8",
    (err) => {}
  );
};

napraviZaImport();
