define-command -docstring "compute some arithmetic aggregations of the selections
    - sum:  sum
    - prod: product
    - mean: arithmetic mean
    - max:  maximum value
    - min:  minimum value
    - stdv: standard deviation
    - var:  variance" \
aggregate-selections -params 1 %{
    eval %sh{
        case $1 in
            sum)
                eval set -- "$kak_quoted_selections"
                res=$( echo $* | sed 's/ /+/g' | bc )
                ;;
            prod)
                eval set -- "$kak_quoted_selections"
                res=$( echo $* | sed 's/ /*/g' | bc )
                ;;
            mean)
                eval set -- "$kak_quoted_selections"
                nargs=$#
                sum=$( echo $* | sed 's/ /+/g' | bc )
                res=$( echo "scale=3; $sum / $nargs" | bc )
                ;;
            max)
                eval set -- "$kak_quoted_selections"
                IFS=$'\n'
                res=$( echo "$*" | sort -nr | head -n1 )
                ;;
            min)
                eval set -- "$kak_quoted_selections"
                IFS=$'\n'
                res=$( echo "$*" | sort -n | head -n1 )
                ;;
            stdv)
                eval set -- "$kak_quoted_selections"
                nargs=$#
                delta_sum=0
                sum=$( echo $* | sed 's/ /+/g' | bc )
                mean=$( echo "scale=3; $sum / $nargs" | bc )
                for el in $*; do
                    delta_sum=$( echo "$delta_sum + ($el - $mean)^2" | bc )
                done
                res=$( echo "scale=3; sqrt($delta_sum / $nargs)" | bc )
                ;;
            var)
                eval set -- "$kak_quoted_selections"
                nargs=$#
                delta_sum=0
                sum=$( echo $* | sed 's/ /+/g' | bc )
                mean=$( echo "scale=3; $sum / $nargs" | bc )
                for el in $*; do
                    delta_sum=$( echo "$delta_sum + ($el - $mean)^2" | bc )
                done
                res=$( echo "scale=3; $delta_sum / $nargs" | bc )
                ;;
            *)
                echo "fail unknown aggregation function" && exit 1
                ;;
        esac
        printf "info -title result '%-8s'\n" "$res"
        printf "reg 'r' %s\n" "$res"
    }
}

complete-command -menu aggregate-selections shell-script-candidates %{ printf '%s\n' sum prod mean max min stdv var }

alias global agg aggregate-selections

