# CatmanBinReader

[![Build Status](https://github.com/pjsjipt/CatmanBinReader.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/pjsjipt/CatmanBinReader.jl/actions/workflows/CI.yml?query=branch%3Amain)

This is a [Julia](https://julialang.org) package for reading binary `.bin` files generated by Catman and Catman Easy data acquisition software.

The binary file format was taken from the Python package [APReader](https://github.com/leonbohmann/APReader).

This is ongoing work and there certainly are bugs!

## Usage

To load a file, use the `CatmanReader` method. This method accepts a file name, an `IO` object to the data or a vector with bytes containing the file.

