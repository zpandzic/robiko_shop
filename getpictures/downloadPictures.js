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

const ucitajSlike = async () => {
  const spremljeneSlike = await ucitajPodatke("getpictures/rezultatSlika.json");
  let index = 0;

  for (const katBroj of Object.keys(spremljeneSlike)) {
    const slika = spremljeneSlike[katBroj].slika
      ? spremljeneSlike[katBroj].slika
      : null;
    index++;
    // console.log(slika)

    if (slika) {
      await preuzmiSliku(
        slika,
        katBroj,
        index + "/" + Object.keys(spremljeneSlike).length,
        "katBroj:" + katBroj
      );
    }

    // const imeSlike = katBroj
  }
};

ucitajSlike().catch(console.error);

const preuzmiSliku = async (imageUrl, katBroj, log) => {
  const safeKatBroj = katBroj.replaceAll("/", "$");

  const fileExtension = path.extname(imageUrl);
  const savePath = path.join(saveFolderPath, `${safeKatBroj}${fileExtension}`);

  if (fs.existsSync(savePath)) {
    console.log(log, `Image already exists at ${savePath}`);
    return;
  }

  await axios({
    method: "get",
    url: imageUrl,
    responseType: "stream",
  })
    .then((response) => {
      if (!fs.existsSync(saveFolderPath)) {
        fs.mkdirSync(saveFolderPath);
      }
      response.data.pipe(fs.createWriteStream(savePath));
      console.log(log, `Image downloaded and saved to ${savePath}`);
    })
    .catch((error) => {
      console.error("Error downloading the image:", error);
    });
};
