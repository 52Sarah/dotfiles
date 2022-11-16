#
  ### CH-Specific
  #
  .setup-ch_specific() {
    .tick_bp '[start ] .setup-ch_specific'

    export CCHH_HOME="$HOME/cchh"

    export CCHH_AUG_HOME="$HOME/cchh-extra/canal-aqueduct-tools/aug"
    export CCHH_AUG_VENV="$VIRTUALENVWRAPPER_HOOK_DIR/aug"
    aug() { [[ "$VIRTUAL_ENV" != "$CCHH_AUG_VENV" ]] && . "$CCHH_AUG_VENV/bin/activate"; command aug "$@"; }

    export CH_TICKETS="$HOME/ch-tickets"
    mk-ch-ticket() {
      [[ -z "$2" ]] && eecho "usage: mk-ch-ticket JIRA-ID 'title'" && return 1
      local jira_id="$(upper $1)"; shift
      local title="${1// /-}"; shift
      local ticket_name="$jira_id-$title"
      local ticket_dir="$CH_TICKETS/$ticket_name"
      local notes_file="$ticket_dir/$ticket_name.md"
      [[ -e "$notes_file" ]] && return 0
      [[ ! -e "$ticket_dir" ]] && mkdir -v "$ticket_dir"
      printf '# %s %s\n\n' "$jira_id" "$title" > "$notes_file"
    }

    alias cd-CI-715='cd $CH_TICKETS/CI-715-hcsc-med-accum-add-synthetics'
    alias cd-CH-62846='cd $CH_TICKETS/CH-62846-hcsc-add-rx'

    vault-token-refresh() {
      vault login -method=ldap -no-print username=todd.pierzina password=$SECRET_OKTA_CRED && echo Vault token refreshed.
    }

    # Convert logsearch/kibana's json response to streamlined tab-separated-values file.
    jq-logsearch-to-tsv() {
      # local json_file="$1"; shift
      # [[ -z "$json_file" ]] && eecho "usage: jq-logsearch-to-tsv json_file" && return 1
      # [[ -e "$json_file" ]] && eecho "jq-logsearch-to-tsv: $json_file: No such file" && return 1
      printf 'timestamp\tnamespace\tlevel\tthread\tmessage\tsort\n'
      jq -j '.hits[]|._source.timestamp,"\t",._source.namespace,"\t",._source.level,"\t",._source.thread,"\t",._source.message,"\t",.sort[0],"\n"'
    }
    
    fwf-hcsc-med-accum() {
      local delim="\t"
      if [[ "$1" =~ -d|--delim ]]; then
        delim="$2"
        shift 2
      fi
      vecho "fwf-nice -d "$delim" $@"
      fwf-nice -d "$delim" $@ \
        1 9  10 4  14 9  23 8  31 1  32 15  47 10  57 1  58 15  73 2  75 2 \
        CR  77 8  85 8  93 1  94 1  95 64  159 2  161 3 164 3  167  16  183 12  195 12 \
        CR  207 8  215 8  223 1  224 1  225 64  289 2  291 3  294 3  297 16  313 12  325 12 \
        CR  337 8  345 8  353 1  354 1  355 64  419 2  421 3  424 3  427 16  443 12  455 12 \
        CR  467 8  475 8  483 1  484 1  485 64  549 2  551 3  554 3  557 16  573 12  585 12 \
        CR  597 8  605 8  613 1  614 1  615 64  679 2  681 3  684 3  687 16  703 12  715 12 \
        CR  727 8  735 8  743 1  744 1  745 64  809 2  811 3  814 3  817 16  833 12  845 12 \
        CR  857 8  865 8  873 1  874 1  875 64  939 2  941 3  944 3  947 16  963 12  975 12 \
        CR  987 8  995 8  1003 1  1004 1  1005 64  1069 2  1071 3  1074 3  1077 16  1093 12  1105 12 \
        CR  1117 8  1125 8  1133 1  1134 1  1135 64  1199 2  1201 3  1204 3  1207 16  1223 12  1235 12 \
        CR  1247 8  1255 8  1263 1  1264 1  1265 64  1329 2  1331 3  1334 3  1337 16  1353 12  1365 12 \
        CR  1377 8  1385 8  1393 1  1394 1  1395 64  1459 2  1461 3  1464 3  1467 16  1483 12  1495 12 \
        CR  1507 8  1515 8  1523 1  1524 1  1525 64  1589 2  1591 3  1594 3  1597 16  1613 12  1625 12 \
        CR  1637 8  1645 8  1653 1  1654 1  1655 64  1719 2  1721 3  1724 3  1727 16  1743 12  1755 12 \
        CR  1767 8  1775 8  1783 1  1784 1  1785 64  1849 2  1851 3  1854 3  1857 16  1873 12  1885 12 \
        CR  1897 8  1905 8  1913 1  1914 1  1915 64  1979 2  1981 3  1984 3  1987 16  2003 12  2015 12 \
        CR  2027 8  2035 8  2043 1  2044 1  2045 64  2109 2  2111 3  2114 3  2117 16  2133 12  2145 12 \
        CR  2157 8  2165 8  2173 1  2174 1  2175 64  2239 2  2241 3  2244 3  2247 16  2263 12  2275 12 \
        CR  2287 8  2295 8  2303 1  2304 1  2305 64  2369 2  2371 3  2374 3  2377 16  2393 12  2405 12 \
        CR  2417 8  2425 8  2433 1  2434 1  2435 64  2499 2  2501 3  2504 3  2507 16  2523 12  2535 12 \
        CR  2547 8  2555 8  2563 1  2564 1  2565 64  2629 2  2631 3  2634 3  2637 16  2653 12  2665 12 \
        CR  2677 8  2685 8  2693 1  2694 1  2695 64  2759 2  2761 3  2764 3  2767 16  2783 12  2795 12
    }

    ssh-airflow-test1() {
      eval-echo ssh_uswest2 172.31.19.25
    }
    
    ssh-is-prod() { eeval ssh_uswest2 intersystems.prod.cchh.local; }
    ssh-is-preprod() { eeval ssh_uswest2 intersystems.preprod.cchh.local; }
    ssh-is-pit() { eeval kubectl -n claims-pit exec -it -c intersystems intersystems-claims-pit-0 bash; }
    
    scp-from() {
      [[ -z "$2" ]] && eecho "usage: scp-from remote_host remote_file_spec [local_path] [scp_switches ...]" && return 1
      local remote_host="$1" && shift
      local remote_file="$1" && shift
      local local_path="${1:-.}" && shift
      local scp_switches="$@"
      eeval scp_uswest2 -p -r $scp_switches "$remote_host:$remote_file" "$local_path"
    }
    scp-from--is-preprod() {
      [[ -z "$1" ]] && eecho "usage: scp-from--is-preprod remote_file_spec [local_path] [scp_switches ...]" && return 1
      eeval scp-from intersystems.preprod.cchh.local $@
    }
    scp-from--ibmmq-prod() {
      [[ -z "$1" ]] && eecho "usage: scp-from--ibmmq-prod remote_file_spec [local_path] [scp_switches ...]" && return 1
      eeval scp-from root@192.168.1.1 $@
    }

    scp-to() {
      [[ -z "$2" ]] && eecho "usage: scp-to remote_host [local_file_spec ...] [remote_path] [scp_switches ...]" && return 1
      local remote_host="$1" && shift
      local local_file="$1" && shift
      local remote_path="${1:-.}" && shift
      local scp_switches="$@"
      eeval scp_uswest2 -p -r $scp_switches "$local_file" "$remote_host:$remote_path"
    }
    scp-to--is-preprod() {
      [[ -z "$1" ]] && eecho "usage: scp-to--is-preprod local_file_spec [remote_path] [scp_switches ...]" && return 1
      eeval scp-to intersystems.preprod.cchh.local $@
    }

    scp-to-airflow-test1() {
      [[ -z "$2" ]] && eecho "usage: scp-to-airflow-test1 local_dir_or_name remote_file_spec" && return 1
      local local_path="$1" && shift
      [[ ! -e "$local_path" ]] && eecho "scp-to-airflow-test1: '$local_path': No such file or directory" && return 1
      local remote_file="$1" && shift
      # [[ ! "$remote_file" =~ ^/ ]] && remote_file="/opt/airflow/$remote_file"
      eeval scp_uswest2 -p -r "$local_path" "172.31.19.25:$remote_file"
    }
    scp-sql-file-to-airflow-test1() {
      [[ -z "$1" ]] && eecho "usage: scp-airflow-sql-file sql_file_name" && return 1
      local local_path="$1" && shift
      # scp-to-airflow-test1 "$local_path" "airflow@/opt/airflow/dags/cchh_dags/fileflow/claims_reports/sql_files/$(basename '$local_path')"
      scp-to-airflow-test1 "$local_path" "$(basename "$local_path")"
    }

  #   ssh-ibmmq() {
  #     cat <<-EOF

  # IBM MQ Runbook: https://github.com/collectivehealth/runbooks/tree/master/ibm-mq#connecting

  # $ sudo su - mqm

  # $ runmqsc PCCHH01  # no prompt will appear

  # dis ql(*) all   # or qlocal
  # dis chs(*) where (STATUS eq RUNNING)
  # dis chs(*) where (STATUS ne RUNNING)
  # dis chs(*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME
  # dis chs(INTERSYSTEMS.*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME
  # dis chs(CANAL.*) where (STATUS eq RUNNING) CHLTYPE BYTSRCVD BYTSSENT CHSTADA CHSTATI LSTMSGDA LSTMSGTI RQMNAME

  # dis qstatus(*) where (CURDEPTH gt 100)
  # dis qstatus(*) where (CURDEPTH gt 0)

  # dis chs(CCHH.ESI.CDH)
  # dis qstatus(CCHH.ESI.CDH.TQ)
  # stop channel(CCHH.ESI.CDH)
  # start channel(CCHH.ESI.CDH)

  # dis chs(PCCHH01.TO.CVS.ZQM1)
  # dis qstatus(CCHH.CVS.TQ)
  # stop channel(PCCHH01.TO.CVS.ZQM1)
  # start channel(PCCHH01.TO.CVS.ZQM1)

  # dis chs(CVS.ZQM1.TO.PCCHH01)
  # stop channel(CVS.ZQM1.TO.PCCHH01)
  # dis chs(CVS.ZQM1.TO.PCCHH01)
  # start channel(CVS.ZQM1.TO.PCCHH01)

  # dis chs(ESI.CDH.CCHH)
  # stop channel(ESI.CDH.CCHH)
  # dis chs(ESI.CDH.CCHH)
  # start channel(ESI.CDH.CCHH)

  # # bounce mq
  # $ endmqm PCCHH01
  # $ strmqm PCCHH01

  # EOF
  #     # cchh arrow ssh root@ibm_mq_uswest2_01
  #     eeval ssh_uswest2 root@192.168.1.1
  #   }


    #
    ### Define helper functions/aliases for kubectl
    #
    .setup-ch_k8s_helpers() {
      .tick_bp '[start ] .setup-ch_k8s_helpers'
      
      k-logs--canal-sftp-out-rx-optum-accum() {
        eeval k-logs--app "canal-sftp-out-rx-optum-accum" "$@"
      }
      k-logs--aq-status2() {
        eeval k-logs--ns-app "aq-status" "$@"
        eeval k-logs--ns-app "aq-status-rest" "$@"
      }
      k-logs--is-deploy() {
        eeval kubectl "$@" exec "intersystems-$(kubens --current)-0" -- tail -n 20 /data/deploy_logs/intersystems.log
      }
      
      k-pf--aq-status-rest() {
        local k_service='aq-status-rest'
        local k_port='8103'
        eeval kubectl port-forward services/$k_service $k_port:$k_port
      }
      k-pf--claim-api() {
        local k_service='ingenuity-claim-api'
        local k_port='8087'
        eeval kubectl port-forward services/$k_service $k_port:$k_port
      }
      k-pf--rabbitmq() {
        eeval kubectl port-forward service/rabbitmq 15672:15672
      }

      .tick_bp '[finish] .setup-ch_k8s_helpers'
    }
    .setup-ch_k8s_helpers
    
    . ~/dotfiles/dot_ch_dbenv.sh || .tick_bp '!! failed to load .setup-ch-dbenv'

    .tick_bp "[finish] .setup-ch_specific"
  }
  .setup-ch_specific

