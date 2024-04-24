import { ArtikalZaPretraguSlika } from "./types";

const fs = require("fs");

export const ucitajJSON = <T>(filePath: string): Promise<T> => {
  return new Promise((resolve, reject) => {
    fs.readFile(filePath, "utf8", (err: any, data: string) => {
      if (err) {
        reject(err);
      } else {
        resolve(data ? (JSON.parse(data) as T) : ({} as T));
      }
    });
  });
};

export const sacuvajJSON = (filePath: string, data: Object): Promise<void> => {
  return new Promise((resolve, reject) => {
    fs.writeFile(
      filePath,
      JSON.stringify(data, null, 2),
      "utf8",
      (err: any) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      }
    );
  });
};

export const prepraviKey = (key: string) => {
  return key.replace(/[$#.\[\]\/]/g, "_");
};

export const ucitajCSVVisokaZalihe = (
  csvFilePath: string
): {
  [key: string]: ArtikalZaPretraguSlika;
} => {
  const data: string = fs.readFileSync(csvFilePath, "utf8");

  const lines = data.split("\n");

  const firstLine = lines.shift()?.split(";"); //Rbr.;Šifra robe;Barcode;KatBroj;Naziv robe;JMJ;Stanje;MPC
  if (!firstLine) throw new Error("Nema podataka u fajlu");
  lines.pop();
  lines.pop();

  const artikli: {
    [key: string]: ArtikalZaPretraguSlika;
  } = {};

  const katBrojIndex = firstLine.indexOf("KatBroj");
  const barkodIndex = firstLine.indexOf("Barcode");
  const nazivIndex = firstLine.indexOf("Naziv robe");
  const sifraIndex = firstLine.indexOf("Šifra robe");
  const jmjIndex = firstLine.indexOf("JMJ");
  const stanjeIndex = firstLine.indexOf("Stanje");
  const mpcIndex = firstLine.indexOf("MPC");

  lines.forEach((line) => {
    // console.log(line);
    const parts = line.split(";");

    const katBroj = parts[katBrojIndex];
    const barkod = parts[barkodIndex];
    const naziv = parts[nazivIndex];
    const sifra = parts[sifraIndex];
    const jmj = parts[jmjIndex];
    const stanje = parts[stanjeIndex];
    const mpc = parts[mpcIndex];

    artikli[katBroj] = { katBroj, barkod };
  });

  return artikli;
};
