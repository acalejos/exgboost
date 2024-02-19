# EXGBoost

[![EXGBoost version](https://img.shields.io/hexpm/v/exgboost.svg)](https://hex.pm/packages/exgboost)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/exgboost/)
[![Hex Downloads](https://img.shields.io/hexpm/dt/exgboost)](https://hex.pm/packages/exgboost)
[![Twitter Follow](https://img.shields.io/twitter/follow/ac_alejos?style=social)](https://twitter.com/ac_alejos)
<!-- BEGIN MODULEDOC -->
Elixir bindings to the [XGBoost C API](https://xgboost.readthedocs.io/en/latest/c.html) using [Native Implemented Functions (NIFs)](https://www.erlang.org/doc/man/erl_nif.html).

`EXGBoost` provides an implementation of XGBoost that works with
[Nx](https://hexdocs.pm/nx/Nx.html) tensors.

Xtreme Gradient Boosting (XGBoost) is an optimized distributed gradient
boosting library designed to be highly efficient, flexible and portable.
It implements machine learning algorithms under the [Gradient Boosting](https://en.wikipedia.org/wiki/Gradient_boosting)
framework. XGBoost provides a parallel tree boosting (also known as GBDT, GBM)
that solve many data science problems in a fast and accurate way. The same code
runs on major distributed environment (Hadoop, SGE, MPI) and can solve problems beyond
billions of examples.

## Installation

```elixir
def deps do
[
  {:exgboost, "~> 0.5"}
]
end
```

## API Data Structures

EXGBoost's top-level `EXGBoost` API works directly and only with `Nx` tensors. However, under the hood,
it leverages the structs defined in the `EXGBoost.Booster` and `EXGBoost.DMatrix` modules. These structs
are wrappers around the structs defined in the XGBoost library.
The two main structs used are [DMatrix](https://xgboost.readthedocs.io/en/latest/c.html#dmatrix)
to represent the data matrix that will be used
to train the model, and [Booster](https://xgboost.readthedocs.io/en/latest/c.html#booster)
which represents the model.

The top-level `EXGBoost` API does not expose the structs directly. Instead, the
structs are exposed through the `EXGBoost.Booster` and `EXGBoost.DMatrix` modules. Power users
might wish to use these modules directly. For example, if you wish to use the `Booster` struct
directly then you can use the `EXGBoost.Booster.booster/2` function to create a `Booster` struct
from a `DMatrix` and a keyword list of options. See the `EXGBoost.Booster` and `EXGBoost.DMatrix`
modules source for more implementation details.

## Basic Usage

```elixir
key = Nx.Random.key(42)
{x, key} = Nx.Random.normal(key, 0, 1, shape: {10, 5})
{y, key} = Nx.Random.normal(key, 0, 1, shape: {10})
model = EXGBoost.train(x, y)
EXGBoost.predict(model, x)
```

## Training

EXGBoost is designed to feel familiar to the users of the Python XGBoost library. `EXGBoost.train/2` is the
primary entry point for training a model. It accepts a Nx tensor for the features and a Nx tensor for the labels.
`EXGBoost.train/2` returns a trained`Booster` struct that can be used for prediction. `EXGBoost.train/2` also
accepts a keyword list of options that can be used to configure the training process. See the
[XGBoost documentation](https://xgboost.readthedocs.io/en/latest/parameter.html) for the full list of options.

`EXGBoost.train/2` uses the `EXGBoost.Training.train/1` function to perform the actual training. `EXGBoost.Training.train/1`
and can be used directly if you wish to work directly with the `DMatrix` and `Booster` structs.

One of the main features of `EXGBoost.train/2` is the ability for the end user to provide a custom training function
that will be used to train the model. This is done by passing a function to the `:obj` option. The function must
accept a `DMatrix` and a `Booster` and return a `Booster`. The function will be called at each iteration of the
training process. This allows the user to implement custom training logic. For example, the user could implement
a custom loss function or a custom metric function. See the [XGBoost documentation](https://xgboost.readthedocs.io/en/latest/tutorials/custom_metric_obj.html)
for more information on custom loss functions and custom metric functions.

Another feature of `EXGBoost.train/2` is the ability to provide a validation set for early stopping. This is done
by passing a list of 3-tuples to the `:evals` option. Each 3-tuple should contain a Nx tensor for the features, a Nx tensor
for the labels, and a string label for the validation set name. The validation set will be used to calculate the validation
error at each iteration of the training process. If the validation error does not improve for `:early_stopping_rounds` iterations
then the training process will stop. See the [XGBoost documentation](https://xgboost.readthedocs.io/en/latest/tutorials/param_tuning.html)
for a more detailed explanation of early stopping.

Early stopping is achieved through the use of callbacks. `EXGBoost.train/2` accepts a list of callbacks that will be called
at each iteration of the training process. The callbacks can be used to implement custom logic. For example, the user could
implement a callback that will print the validation error at each iteration of the training process or to provide a custom
setup function for training. See the `EXGBoost.Training.Callback` module for more information on callbacks.

Please notes that callbacks are called in the order that they are provided. If you provide multiple callbacks that modify
the same parameter then the last callback will trump the previous callbacks. For example, if you provide a callback that
sets the `:early_stopping_rounds` parameter to 10 and then provide a callback that sets the `:early_stopping_rounds` parameter
to 20 then the `:early_stopping_rounds` parameter will be set to 20.

You are also able to pass parameters to be applied to the Booster model using the `:params` option. These parameters will
be applied to the Booster model before training begins. This allows you to set parameters that are not available as options
to `EXGBoost.train/2`. See the [XGBoost documentation](https://xgboost.readthedocs.io/en/latest/parameter.html) for a full
list of parameters.

```elixir
EXGBoost.train(X,
              y,
              obj: &EXGBoost.Training.train/1,
              evals: [{X_test, y_test, "test"}],
              learning_rates: fn i -> i/10 end,
              num_boost_round: 10,
              early_stopping_rounds: 3,
              max_depth: 3,
              eval_metric: [:rmse,:logloss]
              )
```

## Prediction

`EXGBoost.predict/2` is the primary entry point for making predictions with a trained model.
It accepts a `Booster` struct (which is the output of `EXGBoost.train/2`).
`EXGBoost.predict/2` returns a Nx tensor containing the predictions.
`EXGBoost.predict/2` also accepts a keyword list of options that can be used to configure the prediction process.

```elixir
preds = EXGBoost.train(X, y) |> EXGBoost.predict(X)
```

## Serialization

  A Booster can be serialized to a file using `EXGBoost.write_*` and loaded from a file
  using `EXGBoost.read_*`. The file format can be specified using the `:format` option
  which can be either `:json` or `:ubj`. The default is `:json`. If the file already exists, it will NOT
  be overwritten by default.  Boosters can either be serialized to a file or to a binary string.
  Boosters can be serialized in three different ways: configuration only, configuration and model, or
  model only. `dump` functions will serialize the Booster to a binary string.
  Functions named with `weights` will serialize the model's trained parameters only. This is best used when the model
  is already trained and only inferences/predictions are going to be performed. Functions named with `config` will
  serialize the configuration only. Functions that specify `model` will serialize both the model parameters
  and the configuration.

### Output Formats

- `read`/`write` -  File.
- `load`/`dump` - Binary buffer.

### Output Contents

- `config` - Save the configuration only.
- `weights` - Save the model parameters only. Use this when you want to save the model to a format that can be ingested by other XGBoost APIs.
- `model` - Save both the model parameters and the configuration.

## Plotting

  `EXGBoost.plot_tree/2` is the primary entry point for plotting a tree from a trained model.
  It accepts an `EXGBoost.Booster` struct (which is the output of `EXGBoost.train/2`).
  `EXGBoost.plot_tree/2` returns a VegaLite spec that can be rendered in a notebook or saved to a file.
  `EXGBoost.plot_tree/2` also accepts a keyword list of options that can be used to configure the plotting process.

  See `EXGBoost.Plotting` for more detail on plotting.

  You can see available styles by running `EXGBoost.Plotting.get_styles()` or refer to the `EXGBoost.Plotting.Styles`
  documentation for a gallery of the styles.

## Kino & Livebook Integration

  `EXGBoost` integrates with [Kino](https://hexdocs.pm/kino/Kino.html) and [Livebook](https://livebook.dev/)
  to provide a rich interactive experience for data scientists.

  EXGBoost implements the `Kino.Render` protocol for `EXGBoost.Booster` structs. This allows you to render
  a Booster in a Livebook notebook.  Under the hood, `EXGBoost` uses [Vega-Lite](https://vega.github.io/vega-lite/)
  and [Kino Vega-Lite](https://hexdocs.pm/kino_vega_lite/Kino.VegaLite.html) to render the Booster.

  See the [`Plotting in EXGBoost`](notebooks/plotting.livemd) Notebook for an example of how to use `EXGBoost` with `Kino` and `Livebook`.

## Examples

  See the example Notebooks in the left sidebar (under the `Pages` tab) for more examples and tutorials
  on how to use EXGBoost.

## Requirements

### Precompiled Distribution

We currenly offer the following precompiled packages for EXGBoost:

```elixir
%{
  "exgboost-nif-2.16-aarch64-apple-darwin-0.5.0.tar.gz" => "sha256:c659d086d07e9c209bdffbbf982951c6109b2097c4d3008ef9af59c3050663d2",
  "exgboost-nif-2.16-x86_64-apple-darwin-0.5.0.tar.gz" => "sha256:05256238700456c57e279558765b54b5b5ed4147878c6861cd4c937472abbe52",
  "exgboost-nif-2.16-x86_64-linux-gnu-0.5.0.tar.gz" => "sha256:ad3ba6aba8c3c2821dce4afc05b66a5e529764e0cea092c5a90e826446653d99",
  "exgboost-nif-2.17-aarch64-apple-darwin-0.5.0.tar.gz" => "sha256:745e7e970316b569a10d76ceb711b9189360b3bf9ab5ee6133747f4355f45483",
  "exgboost-nif-2.17-x86_64-apple-darwin-0.5.0.tar.gz" => "sha256:73948d6f2ef298e3ca3dceeca5d8a36a2d88d842827e1168c64589e4931af8d7",
  "exgboost-nif-2.17-x86_64-linux-gnu-0.5.0.tar.gz" => "sha256:a0b5ff0b074a9726c69d632b2dc0214fc7b66dccb4f5879e01255eeb7b9d4282",
}
```

The correct package will be downloaded and installed (if supported) when you install
the dependency through Mix (as shown above), otherwise you will need to compile
manually.

**NOTE** If MacOS, you still need to install `libomp` even to use the precompiled libraries:

 `brew install libomp`

### Dev Requirements

If you are contributing to the library and need to compile locally or choose to not use the precompiled libraries, you will need the following:

- Make
- CMake
- If MacOS: `brew install libomp`

When you run `mix compile`, the `xgboost` shared library will be compiled, so the first time you compile your project will take longer than subsequent compilations.

You also need to set `CC_PRECOMPILER_PRECOMPILE_ONLY_LOCAL=true` before the first local compilation, otherwise you will get an error related to a missing checksum file.

## Known Limitations

- The XGBoost C API uses C function pointers to implement streaming data types.  The Python ctypes library is able to pass function pointers to the C API which are then executed by XGBoost. Erlang/Elixir NIFs do not have this capability, and as such, streaming data types are not supported in EXGBoost.
- Currently, EXGBoost only works with tensors from the `Nx.Binarybackend`. If you are using any other backend you will need to perform an `Nx.backend_transfer` or `Nx.backend_copy` before training an `EXGBoost.Booster`. This is because Nx tensors are JSON-encoded and serialized before
being sent to XGBoost and the binary backend is required for proper JSON-encoding of the underlying
tensor.
<!-- END MODULEDOC -->
## Roadmap

- [ ] CUDA support
- [ ] [Collective API](https://xgboost.readthedocs.io/en/latest/c.html#collective)?

## License

Licensed under an [Apache-2](https://github.com/acalejos/exgboost/blob/main/LICENSE) license.
