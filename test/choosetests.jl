# This file is a part of Julia. License is MIT: https://julialang.org/license

@doc """

`tests, net_on, exit_on_error, seed = choosetests(choices)` selects a set of tests to be
run. `choices` should be a vector of test names; if empty or set to
`["all"]`, all tests are selected.

This function also supports "test collections": specifically, "linalg"
 refers to collections of tests in the correspondingly-named
directories.

Upon return:
  - `tests` is a vector of fully-expanded test names,
  - `net_on` is true if networking is available (required for some tests),
  - `exit_on_error` is true if an error in one test should cancel
    remaining tests to be run (otherwise, all tests are run unconditionally),
  - `seed` is a seed which will be used to initialize the global RNG for each
    test to be run.

Three options can be passed to `choosetests` by including a special token
in the `choices` argument:
   - "--skip", which makes all tests coming after be skipped,
   - "--exit-on-error" which sets the value of `exit_on_error`,
   - "--seed=SEED", which sets the value of `seed` to `SEED`
     (parsed as an `UInt128`); `seed` is otherwise initialized randomly.
     This option can be used to reproduce failed tests.
""" ->
function choosetests(choices = [])
    testnames = [
        "linalg", "subarray", "core", "inference", "worlds",
        "keywordargs", "numbers", "subtype",
        "printf", "char", "strings", "triplequote", "unicode", "intrinsics",
        "dates", "dict", "hashing", "iobuffer", "staged", "offsetarray",
        "arrayops", "tuple", "reduce", "reducedim", "random", "abstractarray",
        "intfuncs", "simdloop", "vecelement", "sparse",
        "bitarray", "copy", "math", "fastmath", "functional", "iterators",
        "operators", "path", "ccall", "parse", "loading", "bigint",
        "bigfloat", "sorting", "statistics", "spawn", "backtrace",
        "file", "read", "version", "resolve", "namedtuple",
        "mpfr", "broadcast", "complex", "socket",
        "floatapprox", "stdlib", "reflection", "regex", "float16",
        "combinatorics", "sysinfo", "env", "rounding", "ranges", "mod2pi",
        "euler", "show", "lineedit", "replcompletions", "repl",
        "replutil", "sets", "goto", "llvmcall", "llvmcall2", "grisu",
        "nullable", "meta", "stacktraces", "libgit2", "docs",
        "markdown", "serialize", "misc", "threads",
        "enums", "cmdlineargs", "i18n", "workspace", "libdl", "int",
        "checked", "bitset", "floatfuncs", "compile", "distributed", "inline",
        "boundscheck", "error", "ambiguous", "cartesian", "asmvariant", "osutils",
        "channels", "iostream", "specificity", "codegen", "codevalidation",
        "reinterpretarray"
    ]

    if isdir(joinpath(JULIA_HOME, Base.DOCDIR, "examples"))
        push!(testnames, "examples")
    end

    tests = []
    skip_tests = []
    exit_on_error = false
    seed = rand(RandomDevice(), UInt128)

    for (i, t) in enumerate(choices)
        if t == "--skip"
            skip_tests = choices[i + 1:end]
            break
        elseif t == "--exit-on-error"
            exit_on_error = true
        elseif startswith(t, "--seed=")
            seed = parse(UInt128, t[8:end])
        else
            push!(tests, t)
        end
    end

    if tests == ["all"] || isempty(tests)
        tests = testnames
    end

    datestests = ["dates/accessors", "dates/adjusters", "dates/query",
                  "dates/periods", "dates/ranges", "dates/rounding", "dates/types",
                  "dates/io", "dates/arithmetic", "dates/conversions"]
    if "dates" in skip_tests
        filter!(x -> (x != "dates" && !(x in datestests)), tests)
    elseif "dates" in tests
        # specifically selected case
        filter!(x -> x != "dates", tests)
        prepend!(tests, datestests)
    end

    unicodetests = ["unicode/UnicodeError", "unicode/utf8proc", "unicode/utf8"]
    if "unicode" in skip_tests
        filter!(x -> (x != "unicode" && !(x in unicodetests)), tests)
    elseif "unicode" in tests
        # specifically selected case
        filter!(x -> x != "unicode", tests)
        prepend!(tests, unicodetests)
    end

    stringtests = ["strings/basic", "strings/search", "strings/util",
                   "strings/io", "strings/types"]
    if "strings" in skip_tests
        filter!(x -> (x != "strings" && !(x in stringtests)), tests)
    elseif "strings" in tests
        # specifically selected case
        filter!(x -> x != "strings", tests)
        prepend!(tests, stringtests)
    end


    sparsetests = ["sparse/sparse", "sparse/sparsevector", "sparse/higherorderfns"]
    if Base.USE_GPL_LIBS
        append!(sparsetests, ["sparse/umfpack", "sparse/cholmod", "sparse/spqr"])
    end
    if "sparse" in skip_tests
        filter!(x -> (x != "sparse" && !(x in sparsetests)), tests)
    elseif "sparse" in tests
        # specifically selected case
        filter!(x -> x != "sparse", tests)
        prepend!(tests, sparsetests)
    end

    # do subarray before sparse but after linalg
    if "subarray" in skip_tests
        filter!(x -> x != "subarray", tests)
    elseif "subarray" in tests
        filter!(x -> x != "subarray", tests)
        prepend!(tests, ["subarray"])
    end

    linalgtests = ["linalg/triangular", "linalg/qr", "linalg/dense",
                   "linalg/matmul", "linalg/schur", "linalg/special",
                   "linalg/eigen", "linalg/bunchkaufman", "linalg/svd",
                   "linalg/lapack", "linalg/tridiag", "linalg/bidiag",
                   "linalg/diagonal", "linalg/pinv", "linalg/givens",
                   "linalg/cholesky", "linalg/lu", "linalg/symmetric",
                   "linalg/generic", "linalg/uniformscaling", "linalg/lq",
                   "linalg/hessenberg", "linalg/rowvector", "linalg/conjarray",
                   "linalg/blas"]
    if Base.USE_GPL_LIBS
        push!(linalgtests, "linalg/arnoldi")
    end

    if "linalg" in skip_tests
        filter!(x -> (x != "linalg" && !(x in linalgtests)), tests)
    elseif "linalg" in tests
        # specifically selected case
        filter!(x -> x != "linalg", tests)
        prepend!(tests, linalgtests)
    end

    # do ambiguous first to avoid failing if ambiguities are introduced by other tests
    if "ambiguous" in skip_tests
        filter!(x -> x != "ambiguous", tests)
    elseif "ambiguous" in tests
        filter!(x -> x != "ambiguous", tests)
        prepend!(tests, ["ambiguous"])
    end

    net_required_for = ["socket", "distributed", "libgit2"]
    net_on = true
    try
        ipa = getipaddr()
    catch
        warn("Networking unavailable: Skipping tests [" * join(net_required_for, ", ") * "]")
        net_on = false
    end

    if ccall(:jl_running_on_valgrind,Cint,()) != 0 && "rounding" in tests
        warn("Running under valgrind: Skipping rounding tests")
        filter!(x -> x != "rounding", tests)
    end

    if !net_on
        filter!(x -> !(x in net_required_for), tests)
    end

    filter!(x -> !(x in skip_tests), tests)

    tests, net_on, exit_on_error, seed
end
