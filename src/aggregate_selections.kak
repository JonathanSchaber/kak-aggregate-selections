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

        case ${1:-sum} in
            sum)
                prefix="sum: "
                eval set -- "$kak_quoted_selections"
                res=0
                for el in "$@"; do
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    res=$( echo "$res + $el" | bc )
                done
                ;;
            prod)
                prefix="product: "
                eval set -- "$kak_quoted_selections"
                res=1
                for el in "$@"; do
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    res=$( echo "$res * $el" | bc )
                done
                ;;
            mean)
                prefix="mean: "
                eval set -- "$kak_quoted_selections"
                nargs=$#
                sum=0
                for el in "$@"; do
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    sum=$( echo "$sum + $el" | bc )
                done
                res=$( echo "$sum / $nargs" | bc -l )
                ;;
            max)
                prefix="max: "
                eval set -- "$kak_quoted_selections"
                res=
                for el in "$@"; do
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    if [ -z $res ]; then
                        res=$el
                    else
                        [ $( echo "$el > $res" | bc ) -eq 1 ] && res=$el
                    fi
                done
                ;;
            min)
                prefix="min: "
                eval set -- "$kak_quoted_selections"
                res=
                for el in "$@"; do
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    if [ -z $res ]; then
                        res=$el
                    else
                        [ $( echo "$el < $res" | bc ) -eq 1 ] && res=$el
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
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    sum=$( echo "$sum + $el" | bc )
                done
                mean=$( echo "$sum / $nargs" | bc -l )
                for el in "$@"; do
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    delta_sum=$( echo "$delta_sum + ($el - $mean)^2" | bc )
                done
                res=$( echo "sqrt($delta_sum / $nargs)" | bc -l )
                ;;
            var)
                prefix="variance: "
                eval set -- "$kak_quoted_selections"
                nargs=$#
                delta_sum=0
                sum=0
                for el in "$@"; do
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    sum=$( echo "$sum + $el" | bc )
                done
                mean=$( echo "$sum / $nargs" | bc -l )
                for el in "$@"; do
                    el=$( echo "$el" | sed 's/[^0123456789.\-]//g' )
                    delta_sum=$( echo "$delta_sum + ($el - $mean)^2" | bc )
                done
                res=$( echo "$delta_sum / $nargs" | bc -l )
                ;;
            *)
                echo "fail unknown aggregation function" && exit 1
                ;;
        esac

        printf "reg 'r' %s\n" "$res"

        [[ "$res" =~ \. ]] && res=$( printf "%.3f" "$res" | sed 's/0+$//' )
        printf "info -title 'result (rounded)' '\n%s %+15s'\n" "$prefix" "$res"
    }
}

complete-command -menu aggregate-selections shell-script-candidates %{ printf '%s\n' sum prod mean max min stdv var }

alias global agg aggregate-selections

