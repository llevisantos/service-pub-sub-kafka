#!/usr/bin/env bash

# This file contains all the useful functions
# used to configure the SonarQube instance.

# Fail on error

# Constants
SONARQUBE_URL="http://localhost:9000/api"

# Example:
#   $ log $ERROR "Something went wrong" "a_faulty_function"
export INFO="INFO"
export WARNING="WARNING"
export ERROR="ERROR"
log()
{
    msg="[$1] SonarQube: $2"
    if [ -n "$3" ]
    then
        msg="$msg, caused by $3"
    fi
    if [ "$1" = "$INFO" ]
    then
        echo "$msg"
    else
        >&2 echo "$msg"
    fi
}

# wait sonarqube up service
wait_sonarqube_up() {
    sonar_status="DOWN"
    log $INFO "initiating connection with SonarQube.\n"
    apk add curl
    apk add jq
    sleep 15
    while [ "${sonar_status}" != "UP" ];
    do
        sleep 5
        log $INFO "retrieving SonarQube's service status.\n"
        sonar_status=$(curl -s -X GET "localhost:9000/api/system/status" | jq -r '.status')
        log $INFO "SonarQube is ${sonar_status}, expecting it to be UP.\n"
    done
    curl -u admin:admin -X POST "${SONARQUBE_URL}/users/change_password?login=admin&previousPassword=admin&password=devSonar"
    log $INFO "SonarQube is ${sonar_status}."
}
# ADD condition to sonarqube quality gate
add_condition_to_quality_gate() {
    gate_id=$1
    metric_key=$2
    metric_operator=$3
    metric_errors=$4

    log $INFO "adding quality gate condition: ${metric_key} ${metric_operator} ${metric_errors}.\n"

    threshold=()
    if [ "${metric_errors}" != "none" ]; then
        threshold=("--data-urlencode" "error=${metric_errors}")
    fi

    res=$(curl -su "admin:devSonar" \
        --data-urlencode "gateId=${gate_id}" \
        --data-urlencode "metric=${metric_key}" \
        --data-urlencode "op=${metric_operator}" \
        "${threshold[@]}" \
        "${SONARQUBE_URL}/qualitygates/create_condition")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]; then
        log $INFO "metric ${metric_key} condition successfully added.\n"
    else
        log $WARNING "impossible to add ${metric_key} condition $(echo "${res}" | jq '.errors[].msg')\n"
    fi
}
# Create quality gate in Sonarqube
create_quality_gate() {
    log $INFO "creating quality gate.\n"
    res=$(curl -su "admin:devSonar" \
        --data-urlencode "name=EngDev" \
        "${SONARQUBE_URL}/qualitygates/create")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]; then
        log $INFO "successfully created quality gate... now configuring it.\n"
    else
        log $WARNING "impossible to create quality gate $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

    log $INFO "retrieving quality gate ID."
    res=$(curl -su "admin:devSonar" \
        --data-urlencode "name=EngDev" \
        "${SONARQUBE_URL}/qualitygates/show")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]; then
        GATEID=$(echo "${res}" | jq '.id' | tail -c +2 | head -c -2)
        log $INFO "successfully retrieved quality gate ID (ID=$GATEID).\n"
    else
        log $ERROR "impossible to reach quality gate ID $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

    log $INFO "setting quality gate as default gate.\n"
    log "${GATEID}"
    res=$(curl -su "admin:devSonar" \
        --data-urlencode "id=${GATEID}" \
        "${SONARQUBE_URL}/qualitygates/set_as_default")
    if [ -z "$res" ]; then
        log $INFO "successfully set quality gate as default gate.\n"
    else
        log $WARNING "impossible to set quality gate as default gate $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

    log $INFO "adding all conditions of cnes-quality-gate.json to the gate.\n"
    len=$(jq '(.conditions | length)' ./scripts/quality_gate_custom.json)
    quality_gate=$(jq '(.conditions)' ./scripts/quality_gate_custom.json)
    for i in $(seq 0 $((len - 1))); do
        metric=$(echo "$quality_gate" | jq -r '(.['"$i"'].metric)')
        op=$(echo "$quality_gate" | jq -r '(.['"$i"'].op)')
        error=$(echo "$quality_gate" | jq -r '(.['"$i"'].error)')
        add_condition_to_quality_gate "$GATEID" "$metric" "$op" "$error"
    done
}

# Create profile quality gate in Sonarqube
create_quality_profile() {
    log $INFO "creating quality profile.\n"
    res=$(curl --location --request POST -u "admin:devSonar" \
        --data-urlencode "language=java" \
        --data-urlencode "name=Sonar_way_and_Mutation" \
        "${SONARQUBE_URL}/qualityprofiles/create")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]; then
        log $INFO "successfully created quality profile... now configuring it.\n"
    else
        log $WARNING "impossible to create quality profile $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

    log $INFO "change parent of quality profile Sonar_way_and_Mutation to Sonar way.\n"
    res=$(curl --location --request POST -u "admin:devSonar" -w "%{http_code}\n" \
        --data-urlencode "language=java" \
        --data-urlencode "parentQualityProfile=Sonar way" \
        --data-urlencode "qualityProfile=Sonar_way_and_Mutation" \
        "${SONARQUBE_URL}/qualityprofiles/change_parent")
    if [ "$(echo "${res}")" == "204" ]; then
        log $INFO "successfully change parent of quality profile Sonar_way_and_Mutation to Sonar way.\n"
    else
        log $WARNING "impossible change parent of quality profile Sonar_way_and_Mutation to Sonar way $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

    log $INFO "set Sonar_way_and_Mutation as default quality profile.\n"
    res=$(curl --location --request POST -u "admin:devSonar" -w "%{http_code}\n" \
        --data-urlencode "language=java" \
        --data-urlencode "qualityProfile=Sonar_way_and_Mutation" \
        "${SONARQUBE_URL}/qualityprofiles/set_default")
    if [ "$(echo "${res}")" == "204" ]; then
        log $INFO "successfully set Sonar_way_and_Mutation as default quality profile.\n"
    else
        log $WARNING "impossible set Sonar_way_and_Mutation as default quality profile $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

    log $INFO "retrieving target quality profile key."
    res=$(curl --location --request POST -u "admin:devSonar" \
        --data-urlencode "defaults=true" \
        --data-urlencode "language=java" \
        --data-urlencode "qualityProfile=Sonar_way_and_Mutation" \
        "${SONARQUBE_URL}/qualityprofiles/search")
    log "${res}"
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]; then
        TARGETKEY=$(echo "${res}" | jq '.profiles[0].key' | tail -c +2 | head -c -2)
        log $INFO "successfully retrieved target quality profile key (KEY=$TARGETKEY).\n"
    else
        log $ERROR "impossible to reach target quality profile key $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

    log $INFO "retrieving source quality profile key."
    res=$(curl --location --request POST -u "admin:devSonar" \
        --data-urlencode "language=java" \
        --data-urlencode "qualityProfile=Mutation Analysis" \
        "${SONARQUBE_URL}/qualityprofiles/search")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]; then
        SOURCEKEY=$(echo "${res}" | jq '.profiles[0].key' | tail -c +2 | head -c -2)
        log $INFO "successfully retrieved source quality profile key (KEY=$SOURCEKEY).\n"
    else
        log "ERROR impossible to reach source quality profile key $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

    log $INFO "active rules of Mutation Analysis on Sonar_way_and_Mutation profile.\n"
    res=$(curl -v --location --request POST -u "admin:devSonar" \
        --data-urlencode "language=java" \
        --data-urlencode "tags=mutation-operator" \
        --data-urlencode "qprofile=${SOURCEKEY}" \
        --data-urlencode "targetKey=${TARGETKEY}" \
        "${SONARQUBE_URL}/qualityprofiles/activate_rules")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]; then
        log $INFO "successfully active rules of Mutation Analysis on Sonar_way_and_Mutation profile.\n"
    else
        log $WARNING "impossible active rules of Mutation Analysis on Sonar_way_and_Mutation profile $(echo "${res}" | jq '.errors[].msg')\n"
        return
    fi

}

wait_sonarqube_up
create_quality_profile
create_quality_gate

