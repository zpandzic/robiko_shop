const axios = require("axios");
const fs = require("fs");
const path = require("path");

const saveFolderPath = "getpictures/slike";

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

const preuzmiSliku = async (imageUrl, katBroj, log) => {
  const safeKatBroj = katBroj.replaceAll("/", "$");

  const fileExtension = path.extname(imageUrl);
  const savePath = path.join(saveFolderPath, `${safeKatBroj}${fileExtension}`);

  if (fs.existsSync(savePath)) {
    console.log(log, `Image already exists at ${savePath}`);
    return;
  }

  try {
    const response = await axios({
      method: "get",
      url: imageUrl,
      responseType: "stream",
    });
    if (!fs.existsSync(saveFolderPath)) {
      fs.mkdirSync(saveFolderPath, { recursive: true });
    }
    response.data.pipe(fs.createWriteStream(savePath));
    console.log(log, `Image downloaded and saved to ${savePath}`);
  } catch (error) {
    console.error("Error downloading the image:", error);
  }

  // await axios({
  //   method: "get",
  //   url: imageUrl,
  //   responseType: "stream",
  // })
  //   .then((response) => {
  //     if (!fs.existsSync(saveFolderPath)) {
  //       fs.mkdirSync(saveFolderPath);
  //     }
  //     response.data.pipe(fs.createWriteStream(savePath));
  //     console.log(log, `Image downloaded and saved to ${savePath}`);
  //   })
  //   .catch((error) => {
  //     console.error("Error downloading the image:", error);
  //   });
};

const ucitajSlike = async (maxParalelno = 5) => {
  const spremljeneSlike = await ucitajPodatke("getpictures/rezultatSlikaNuic.json");
  const keys = Object.keys(spremljeneSlike);
  let obrade = [];

  for (let i = 0; i < keys.length; i++) {
    const katBroj = keys[i];
    let slika = spremljeneSlike[katBroj] ? spremljeneSlike[katBroj] : null;

    if (slika) {
      // console.log(slika)
      if (!slika.includes("https://")) {
        slika = `https://digital-assets.tecalliance.services/images/400/${slika}`;
      }

      obrade.push(
        preuzmiSliku(
          slika,
          katBroj,
          `${i + 1}/${keys.length}, katBroj: ${katBroj}`
        )
      );
    }

    // Kada dostignemo maksimalni broj paralelnih preuzimanja ili dođemo do kraja liste
    if (obrade.length >= maxParalelno || i === keys.length - 1) {
      await Promise.all(obrade);
      obrade = []; // Resetiramo niz za sljedeću grupu preuzimanja
    }
  }
};

ucitajSlike(100).catch(console.error);
