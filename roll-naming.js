const fs = require('fs').promises
const path = require('path')


function formatPhotoName (imageDetails) {
  let year = `${imageDetails.year}`.padStart(4, '0')
  let rollIndex = `${imageDetails.rollIndex}`.padStart(3, '0')
  let frameIndex = `${imageDetails.frameIndex}`.padStart(2, '0')

  return `${year}_roll-${rollIndex}_frame-${frameIndex}_${imageDetails.cameraAndLens}_${imageDetails.film}_${imageDetails.actualISO}.${imageDetails.extension}`
}

function isPhotograph (fileName) {
  return fileName.endsWith('.tif')
}

let validFilmTypes = new Set([
  'kodak-portra-400',
  'ilford-delta-3200',
  'ilford-xp2-400',
  'fuji-neopan-acros-ii-100',
  'kodak-ektar-100'
])

let validISO = new Set([
  50,
  100,
  200,
  400,
  800,
  1600,
  3200,
  6400
])

async function main () {
  let [_node, _script, dirPath, rollIndex, film, actualISO] = process.argv

  if (!Number.isInteger(Number.parseInt(rollIndex, 10))) {
    console.error(`Invalid roll index: ${rollIndex}`)
    process.exit(1)
    return
  }

  if (!validFilmTypes.has(film)) {
    console.error(`Invalid film: ${film}`)
    process.exit(2)
    return
  }

  if (!validISO.has(Number.parseInt(actualISO, 10))) {
    console.error(`Invalid ISO: ${actualISO}`)
    process.exit(3)
    return
  }

  let files = (await fs.readdir(dirPath))
                .filter(isPhotograph)
                .sort()
                .reverse()

  await Promise.all(files.map((oldFileName, frameIndex) => {
    let extension = oldFileName.replace(/.*\./, '')

    let newFileName = formatPhotoName({
      year: new Date().getFullYear(),
      rollIndex,
      frameIndex: frameIndex + 1,
      cameraAndLens: 'rolleicord-xenar',
      film,
      actualISO,
      extension
    })

    let oldFilePath = path.join(dirPath, oldFileName)
    let newFilePath = path.join(dirPath, newFileName)

    console.log(oldFileName, newFileName)

    return fs.rename(oldFilePath, newFilePath)
  }))
}

main().then(() => console.log('Done.'))
