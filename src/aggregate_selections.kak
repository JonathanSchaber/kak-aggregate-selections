define-command -docstring "
compute some arithmetic aggregations of the selections
    - sum:  sum
    - prod: product
    - mean: arithmetic mean
    - med:  median
    - max:  maximum value
    - min:  minimum value
    - stdv: standard deviation
    - var:  variance
if the function is invoked without specifying a parameter, it defaults to 'sum'" \
aggregate-selections -params ..1 %{
    eval %sh{
        [ $kak_selection_count -eq 1 ] && { echo "fail 'only 1 selection - nothing to aggregate'"; exit 1; }

        not_del="[\-+*/^.0123456789\n]"

        case ${1:-sum} in
            sum)
                prefix="sum: "
                eval set -- "$kak_quoted_selections"
                res=0
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    res=$( printf "%s + %s\n" $res "($el)" | bc -l )
                done
                ;;
            prod)
                prefix="product: "
                eval set -- "$kak_quoted_selections"
                res=1
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    res=$( printf "%s * %s\n" $res "($el)" | bc -l )
                done
                ;;
            mean)
                prefix="mean: "
                eval set -- "$kak_quoted_selections"
                nargs=$#
                sum=0
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    sum=$( printf "%s + %s\n" $sum "($el)" | bc -l )
                done
                res=$( printf "%s / %s\n" $sum $nargs | bc -l )
                ;;
            med)
                prefix="median: "
                eval set -- "$kak_quoted_selections"
                nargs=$#
                is_even=$( printf "%s %% 2\n" $nargs | bc )
                arr=()
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    arr+=( $( printf "%s\n" "($el)" | bc -l ) )
                done
                IFS=$'\n' sorted=( $( sort -n <<< ${arr[*]} ) )
                unset IFS
                if [ $is_even -eq 0 ]; then
                    num1=$( printf "(%s / 2) - 1\n" $nargs | bc )
                    num2=$(( $num1 + 1 ))
                    el1=${sorted[$num1]}
                    el2=${sorted[$num2]}
                    res=$( printf "(%s + %s) / 2\n" $el1 $el2 | bc -l )
                else
                    num=$( printf "scale=0; (%s / 2) / 1\n" $nargs | bc )
                    res=${sorted[$num]}
                fi
                ;;
            max)
                prefix="max: "
                eval set -- "$kak_quoted_selections"
                res=
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    if [ -z $res ]; then
                        res=$( printf "%s\n" "$el" | bc -l )
                    else
                        el=$( printf "%s\n" "$el" | bc -l )
                        [ $( printf "%s > %s\n" $el $res | bc -l ) -eq 1 ] && res=$el
                    fi
                done
                ;;
            min)
                prefix="min: "
                eval set -- "$kak_quoted_selections"
                res=
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    if [ -z $res ]; then
                        res=$( printf "%s\n" "$el" | bc -l )
                    else
                        el=$( printf "%s\n" "$el" | bc -l )
                        [ $( printf "%s < %s\n" $el $res | bc -l ) -eq 1 ] && res=$el
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
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    sum=$( printf "%s + %s\n" $sum "($el)" | bc -l )
                done
                mean=$( printf "%s / %s\n" $sum $nargs | bc -l )
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
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
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    sum=$( printf "%s + %s\n" $sum "($el)" | bc -l )
                done
                mean=$( printf "%s / %s\n" $sum $nargs | bc -l )
                for el in "$@"; do
                    el=$( printf "%s\n" "$el" | tr -cd $not_del )
                    delta_sum=$( printf "%s + (%s - %s)^2\n" $delta_sum "($el)" $mean | bc -l )
                done
                res=$( printf "%s / %s\n" $delta_sum $nargs | bc -l )
                ;;
            *)
                echo "fail unknown aggregation function" && exit 1
                ;;
        esac

        printf "reg 'r' %s\n" $res

        expr $res : '.*\..*' >/dev/null && res=$( printf "%.3f" $res | sed -E 's/\.?0+$//' )
        printf "info -title 'result (rounded)' '\n%s %+15s'\n" "$prefix" $res
    }
}

complete-command -menu aggregate-selections shell-script-candidates %{ printf '%s\n' sum prod mean med max min stdv var }

alias global agg aggregate-selections

