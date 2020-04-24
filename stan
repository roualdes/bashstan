#!/usr/bin/env bash

# BSD 3-Clause License
# Copyright (c) 2019, Edward A. Roualdes
# All rights reserved.
# See LICENSE in root of this project.

cwd="$(pwd)"
# Assumes stanflow cloned to $HOME, change if not the case
repo="$HOME/stan"
cmdstan="$HOME/cmdstan" # "$repo/src/stanflow/cmdstan" #

# defaults
c=4                             # chains
t=10                            # max_treedepth
d=0.8                           # adapt_delta
w=1000                          # num_warmup
N=2000                          # num_samples
s=$RANDOM                       # random seed
m="model"                      # model directory
o="output"                     # output directory
e="diag_e"                     # metric

# TODO fill in the rest of these optional flags
# TODO add help message
# TODO a note about self-referential commands: make-stan, update-stan
# TODO a note about spaces in program names
# TODO double check arguments to make-stan

update_repos() {
    git -C "$1" checkout develop
    git -C "$1" reset --hard HEAD
    git -C "$1" pull --no-edit origin develop
}

############################### SAMPLE ###############################
if [ "$1" == "sample" ]
then
    shift
    # process run options
    while getopts ":c:e:t:d:w:N:s:o:m:" opt; do
      case ${opt} in
        c )                     # chains
            c="$OPTARG"
            ;;
        e )                     # metric
            e="$OPTARG"
            ;;
        t )                     # max tree depth
            t="$OPTARG"
            ;;
        d )                     # adapt delta
            d="$OPTARG"
            ;;
        w )                     # warmup
            w="$OPTARG"
            ;;
        N )                     # samples
            N="$OPTARG"
            ;;
        s )                     # seed
            s="$OPTARG"
            ;;
        o )                     # output directory
            o="$OPTARG"
            ;;
        m )                     # model directory
            m="$OPTARG"
            ;;
        a )                     # algorithm
            a="$OPTARG"
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
        : )
            echo "Invalid Option: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
      esac
    done
    shift $((OPTIND -1))

    target="$1"
    output_dir="${target}_${o}"
    mkdir -p "$output_dir"
    model_dir="${target}_${m}"

    seq -w 1 "$c" | parallel --line-buffer command "$model_dir/$target" method=sample algorithm=hmc metric="$e" num_warmup="$w" num_samples="$N" adapt delta="$d" algorithm=hmc engine=nuts max_depth="$t" random seed="$s" id={} data file="$2" output file="$output_dir/samples{}.csv" > /dev/null


############################ FIXED_PARAM #############################
elif [ "$1" == "fixed" ]
then
    shift
    # process run options
    while getopts ":c:N:s:o:m:" opt; do
      case ${opt} in
        c )                     # chains
            c="$OPTARG"
            ;;
        N )                     # samples
            N="$OPTARG"
            ;;
        s )                     # seed
            s="$OPTARG"
            ;;
        o )                     # output directory
            o="$OPTARG"
            ;;
        m )                     # model directory
            m="$OPTARG"
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
        : )
            echo "Invalid Option: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
      esac
    done
    shift $((OPTIND -1))

    target="$1"
    output_dir="{$target}_${o}"
    mkdir -p "$output_dir"
    model_dir="${target}_${m}"

    seq -w 1 "$c" | parallel --line-buffer command "$model_dir/$target" sample algorithm=fixed_param num_samples="$N" random seed="$s" id={} data file="$2" output file="$output_dir/samples{}.csv"


############################## OPTIMIZE ##############################
elif [ "$1" == "optimize" ]
then
    shift
    # process run options
    while getopts ":s:" opt; do
      case ${opt} in
        s )
            s="$OPTARG"
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
        : )
            echo "Invalid Option: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
      esac
    done
    shift $((OPTIND -1))
    output_dir="./${1}_${o}"
    command "$1" optimize data file="$2" random seed="$s"


############################### UPDATE ###############################
elif [ "$1" == "update-stan" ]
then

    update_repos "$cmdstan"
    update_repos "$cmdstan/stan"
    update_repos "$cmdstan/stan/lib/stan_math"


############################ COMPILE STAN ############################
elif [ "$1" == "make-stan" ]
then
    shift
    cd "$cmdstan" \
        && make -j3 -B "$@" build


########################### COMPILE MODEL ############################
else
    target="$1"
    shift
    # process run options
    while getopts ":m:" opt; do
        case ${opt} in
            m )                     # model directory
                m="$OPTARG"
                ;;
        esac
    done
    shift $((OPTIND -1))

    model_dir="./${target}_${m}"
    # compile and move
    make "$cwd/$target" -C "$cmdstan"
    mkdir -p "$model_dir"
    mv "$target" "$target.o" "$target.hpp" "$model_dir/"
fi
