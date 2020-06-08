# Useful scripts
All Shell scripts are tested on GNU bash, version 4.4.20(1)-release.

## Dependencies
* `webp` to convert image to webp format.

## Parallel
Parallel helpers limit the number of background jobs by the processor logic number.

### How to use it ?
```bash
# At the beggining of your script
# Import helpers/parallel file
. "<path to helpers/parallel>"

# Then init required variable
parallel::init

# Run command(s)
declare -a cmd=(sleep 5)
parallel::run cmd

# Wait for all jobs
parallel::wait
```

## Benchmark
Code used to benchmark scripts based on UNIX timestamp in second with the command `date "+%s"`.

```bash
declare -r -i start_time="$(date "+%s")"
parallel::init [max number of background jobs]
# Run some jobs with the command below
# Where cmd is an array describe a command like: (sleep 5)
parallel::run cmd
declare -r -i end_time="$(date "+%s")"
echo "$((end_time - start_time)) seconds"
```

All result are tested on my machine with 8 logic processors `_NPROCESSORS_ONLN`.

### Compress img
Command line:

```shell
$ ./multimedia/compress-img.sh --webp --force <directory with 10 png picture>
```

| Max number of background jobs | Total time (in second) |
| :--------:                    | :-------:              |
| 8                             | 4, 3                   |
| 6                             | 4                      |
| 4                             | 4                      |
| 2                             | 5, 6                   |
| 1                             | 11, 12                 |

N.B: Result with 4, 6 and 8 background jobs are the similar because jobs have the time to finish.
So algorithm wait jobs only in script end.
