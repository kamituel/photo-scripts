#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const { exit } = require('process')
const { extname } = require('path')

let [_node, _script, ...files] = Array.from(process.argv)

if (files.length === 0) {
  console.error('Usage: script.js file1 file2 ...')
  exit(1)
}

let nonexistentFiles = files.filter(s => !doesFileExists(s))

if (nonexistentFiles.length !== 0) {
  console.error('The following files do not exist:')
  nonexistentFiles.forEach(s => `  - ${s}`)
  exit(1)
}

files.forEach(renameFile)

function doesFileExists (filePath) {
  return fs.existsSync(filePath)
}

function renameFile (filePath) {
  let newName = path.basename(filePath)
                    .replace(/.*?(\d+)\.(.+)/, (_, sequenceNumber, extension) => {
                      let paddedSequence = `${sequenceNumber}`.padStart(3, '0')
                      return `${paddedSequence}.${extension}`
                    })
  let newPath = path.join(path.dirname(filePath), newName)
  console.log(`> Rename: ${filePath} to ${newPath}`)
  fs.renameSync(filePath, `${newPath}`)
}
