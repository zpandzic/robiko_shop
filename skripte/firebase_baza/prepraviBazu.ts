import { ArtikalZaPretraguSlika } from "../types";
import {
  prepraviKey,
  sacuvajJSON,
  ucitajCSVVisokaZalihe,
  ucitajJSON,
} from "../utils";

const exportURL =
  "/Users/zpandzic/projects/robiko_shop/skripte/firebase_baza/robikoshop-1df62-default-rtdb-export.json";

const slikeZaImport =
  "/Users/zpandzic/projects/robiko_shop/skripte/nuicPretragaSlika/slike_visoka_zalihe.json";
const csvZaImport =
  "/Users/zpandzic/projects/robiko_shop/assets/csv/Visoka_zalihe_18_04_2024.csv";
const importJSON =
  "/Users/zpandzic/projects/robiko_shop/skripte/firebase_baza/zaImport.json";

type FirebaseData = {
  [key: string]: FireaseItem;
};

type FireaseItem = {
  barkod: string;
  katBroj: string;
  listingId?: string;
  price?: number;
  slika: string;
};

type ItemZaImport = {
  katBroj: string;
  slika: string | null;
  barkod: string;
};

async function main() {
  // const data = await ucitajJSON<FirebaseData>(exportURL);
  // console.log(Object.keys(data).length);

  const slike = await ucitajJSON<{
    [key: string]: string;
  }>(slikeZaImport);
  console.log(`Ucitano ${Object.keys(slike).length} slika`);

  const csvData: {
    [key: string]: ArtikalZaPretraguSlika;
  } = ucitajCSVVisokaZalihe(csvZaImport);
  console.log(`Ucitano ${Object.keys(csvData).length} artikala iz CSV-a`);

  const zaImport = prepraviZaImport(csvData, slike);

  console.log(`Za import: ${Object.keys(zaImport).length}`);

  await sacuvajJSON(importJSON, zaImport);
  console.log(`Sacuvano u ${importJSON}`);
}

main();

const prepraviZaImport = (
  csvData: {
    [key: string]: ArtikalZaPretraguSlika;
  },
  slike: {
    [key: string]: string;
  }
): {
  [key: string]: ItemZaImport;
} => {
  const zaImport: {
    [key: string]: ItemZaImport;
  } = {};

  let bezSlike = 0;
  let prepravljeniKljucevi = 0;

  Object.keys(csvData).forEach((key) => {
    const item = csvData[key];
    const slika = slike[key];
    if (!slika) {
      bezSlike++;
    }

    const noviKey = prepraviKey(key);

    if (noviKey !== key) {
      // console.log(`Prepravljen key: ${key} -> ${noviKey}`);
      prepravljeniKljucevi++;
    }

    zaImport[noviKey] = {
      katBroj: item.katBroj,
      barkod: item.barkod,
      slika: slika ?? null,
    };
  });

  console.log(
    `Bez slike: ${bezSlike} proizvoda od ${Object.keys(csvData).length}`
  );
  console.log(`Prepravljeni kljucevi: ${prepravljeniKljucevi}`);
  console.log(`Za import: ${Object.keys(zaImport).length}`);

  return zaImport;
};

// const zaImport: {
//   [key: string]: ItemZaImport;
// } = {};

// let bezSlike = 0;
// let prepravljeniKljucevi = 0;

// Object.keys(csvData).forEach((key) => {
//   const item = csvData[key];
//   const slika = slike[key];
//   if (!slika) {
//     bezSlike++;
//   }

//   const noviKey = prepraviKey(key);

//   if (noviKey !== key) {
//     // console.log(`Prepravljen key: ${key} -> ${noviKey}`);
//     prepravljeniKljucevi++;
//   }

//   zaImport[noviKey] = {
//     katBroj: item.katBroj,
//     barkod: item.barkod,
//     slika: slika ?? null,
//   };
// });

// console.log(
//   `Bez slike: ${bezSlike} proizvoda od ${Object.keys(csvData).length}`
// );
// console.log(`Prepravljeni kljucevi: ${prepravljeniKljucevi}`);
// console.log(`Za import: ${Object.keys(zaImport).length}`);
