define-command -docstring "
compute some arithmetic aggregations of the selections
    - sum:  sum
    - prod: product
    - mean: arithmetic mean
    - max:  maximum value
    - min:  minimum value
    - stdv: standard deviation
    - var:  variance
if the function is invoked without specifying a parameter, it defaults to 'sum'" \
aggregate-selections -params ..1 %{
    eval %sh{
        [ $kak_selection_count -eq 1 ] && { echo "fail 'only 1 selection - nothing to aggregate'"; exit 1; }

        del="[\-+*/.0123456789\n]"

        case ${1:-sum} in
            sum)
                prefix="sum: "
                eval set -- "$kak_quoted_selections"
                res=0
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    res=$( printf "%s + %s\n" $res "($el)" | bc -l )
                done
                ;;
            prod)
                prefix="product: "
                eval set -- "$kak_quoted_selections"
                res=1
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    res=$( printf "%s * %s\n" $res "($el)" | bc -l )
                done
                ;;
            mean)
                prefix="mean: "
                eval set -- "$kak_quoted_selections"
                nargs=$#
                sum=0
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    sum=$( printf "%s + %s\n" $sum "($el)" | bc -l )
                done
                res=$( printf "%s / %s\n" $sum $nargs | bc -l )
                ;;
            max)
                prefix="max: "
                eval set -- "$kak_quoted_selections"
                res=
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    if [ -z $res ]; then
                        res=$( printf "%s\n" "$el" | bc -l )
                    else
                        [ $( printf "%s > %s\n" "($el)" $res | bc -l ) -eq 1 ] &&
                        res=$( printf "%s\n" "$el" | bc -l )
                    fi
                done
                ;;
            min)
                prefix="min: "
                eval set -- "$kak_quoted_selections"
                res=
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    if [ -z $res ]; then
                        res=$( printf "%s\n" "$el" | bc -l )
                    else
                        [ $( printf "%s < %s\n" "($el)" $res | bc -l ) -eq 1 ] &&
                        res=$( printf "%s\n" "$el" | bc -l )
                    fi
                done
                ;;
            stdv)
                prefix="standard deviation: "
                eval set -- "$kak_quoted_selections"
                nargs=$#
                delta_sum=0
                sum=0
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    sum=$( printf "%s + %s\n" $sum "($el)" | bc -l )
                done
                mean=$( printf "%s / %s\n" $sum $nargs | bc -l )
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    delta_sum=$( printf "%s + (%s - %s)^2\n" $delta_sum "($el)" $mean | bc -l )
                done
                res=$( printf "sqrt(%s / %s)\n" $delta_sum $nargs | bc -l )
                ;;
            var)
                prefix="variance: "
                eval set -- "$kak_quoted_selections"
                nargs=$#
                delta_sum=0
                sum=0
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    sum=$( printf "%s + %s\n" $sum "($el)" | bc -l )
                done
                mean=$( printf "%s / %s\n" $sum $nargs | bc -l )
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $del )
                    delta_sum=$( printf "%s + (%s - %s)^2\n" $delta_sum "($el)" $mean | bc -l )
                done
                res=$( printf "%s / %s\n" $delta_sum $nargs | bc -l )
                ;;
            *)
                echo "fail unknown aggregation function" && exit 1
                ;;
        esac

        printf "reg 'r' %s\n" $res

        expr $res : '.*\..*' >/dev/null && res=$( printf "%.3f" $res | sed -E 's/.?0+$//' )
        printf "info -title 'result (rounded)' '\n%s %+15s'\n" "$prefix" $res
    }
}

complete-command -menu aggregate-selections shell-script-candidates %{ printf '%s\n' sum prod mean max min stdv var }

alias global agg aggregate-selections

