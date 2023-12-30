// komanda za pokrecanje: node --experimental-fetch getPictures.js

const fs = require("fs");
const path = require("path");

const PHPSESSID = "PHPSESSID=fo2uqkohkrito1tqkj5pc35nr0";

const dohvatiSliku = (katBroj) => {
  console.log("dohvatiSliku", katBroj);
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
        katBroj +
        "&pattern_type=10&search_show_attributes=1&search_only_on_stock=0&search_show_price=1",
      method: "POST",
    }
  ).then((response) => response.json());
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

// dohvatiSliku("VE80030");

const listaKatBrojevaPath = path.join("listaKatBrojeva.json");
const nuicFilePath = path.join("nuic.json");

const obradiKatBrojeve = async (katBrojevi, artikliNuic) => {
  for (const KatBroj of katBrojevi) {
    if (!artikliNuic[KatBroj]) {
      const data = await dohvatiSliku(KatBroj);
      Object.keys(data.resultData).forEach((key) => {
        if (key === "debug") return;
        const artikl = data.resultData[key];
        artikliNuic[artikl.no] = artikl;
      });
    }
  }
  return artikliNuic;
};

Promise.all([ucitajPodatke(listaKatBrojevaPath), ucitajPodatke(nuicFilePath)])
  .then(([katBrojevi, artikliNuic]) =>
    obradiKatBrojeve(katBrojevi, artikliNuic)
  )
  .then((artikliNuic) => {
    fs.writeFile(
      nuicFilePath,
      JSON.stringify(artikliNuic, null, 2),
      "utf8",
      (err) => {
        if (err) {
          console.error("Error writing to the file:", err);
        } else {
          console.log("File updated successfully");
        }
      }
    );
  })
  .catch((err) => {
    console.error("Error:", err);
  });
