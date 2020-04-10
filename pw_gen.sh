#!/bin/bash
###################################################
# encoding: utf-8
# Author:                 gaopq
# Version:                1.0
# Email:                  peiqianggao@foxmail.com
# Date:                   2020
# Description:            密码生成脚本(幂等)
# 1) account 账号可以为空，账号为空时以 salt + domain 生成密码
# 2）密码规则：
#   - 四种规格：8 - 23 位中取四种规格
#   - 必须包含：数字 + 下划线 + 小写字母 + 大写字母
#   - 从加密串倒序找一个可用的数字作为插入下划线的下标, 如果没有找到, 则将下划线插入到第一位
#   - 如果加密串前缀没有数字, 从倒序加密串中找第一位数字插入到加密串前缀第一位
#   - 如果加密串前缀没有小写字母, 从倒序加密串中找第一位小写字母插入到加密串前缀第一位
#   - 如果加密串前缀没有大写字母, 从倒序加密串中找第一位大写字母插入到加密串前缀第一位
# TODO 记录输入的 product 和 account
###################################################

set -u
function genPassword() {
    local enStr=${1}
    local len=${2}
    local prefix=${enStr:0:${len}-1}
    local numberFlag
    local lowerCaseFlag
    local upperCaseFlag
    local arr=$(echo ${prefix} | grep -o .)
    for i in ${arr[*]}
    do
        [[ -z ${numberFlag} ]] && [[ ${i} =~ ^[0-9] ]] && numberFlag=1 && continue
        [[ -z ${lowerCaseFlag} ]] && [[ ${i} =~ ^[a-z] ]] && lowerCaseFlag=1 && continue
        [[ -z ${upperCaseFlag} ]] && [[ ${i} =~ ^[A-Z] ]] && upperCaseFlag=1 && continue
    done

    local _index
    local number
    local lowerLetter
    local upperLetter
    local reverseArr=$(echo -n ${enStr} | rev | grep -o .)
    for i in ${reverseArr[*]}
    do
        if [[ ${i} =~ ^[0-9] ]]
        then
            [[ ${_index} -eq 0 ]] && [[ ${i} -le $(expr ${len} - 1) ]] && _index=${i}
            [[ -z ${numberFlag} ]] && number=${i}
        else
            if [[ -z ${lowerCaseFlag} || -z ${upperCaseFlag} ]]
            then
                if [[ ${i} =~ ^[a-z] ]]
                then
                    [[ -z ${lowerCaseFlag} ]] && lowerLetter=${i}
                elif [[ ${i} =~ ^[A-Z] ]]
                then
                    [[ -z ${upperCaseFlag} ]] && upperLetter=${i}
                fi
            fi
        fi
    done
    _index=${_index:-0}
    [[ -z ${numberFlag} ]] && prefix=${number:-1}${prefix}
    [[ -z ${lowerCaseFlag} ]] && prefix=${lowerLetter:-x}${prefix}
    [[ -z ${upperCaseFlag} ]] && prefix=${upperLetter:-X}${prefix}
    prefix=${prefix:0:${_index}}_${prefix:${_index}:${len}}

    echo ${prefix}
}

function genEncryptedStr() {
    # Params: your personal key - $1, product or domain name - $2, account(may be empty) - $3
    local salt=$(echo -n "${1}" | md5sum | cut -d ' ' -f1)
    local pw=$(echo -n "${2}:${3}:${salt}" | sha256sum | cut -d ' ' -f1 | base64)

    echo ${pw}
}

function usage() {
    echo "This is help doc"
}

s=$(genEncryptedStr "$1" "$2" "${3:-}")
s="ZjQzZTM0ZjlkZDcxNWYxMmUxMmIyMWIxNmZmNmQyNDEwZWE2MjFkNDIxZGMyNzAzYjA0YWI5N2EyZTE4NWM5Mgo"
echo "加密: ${s}"
genPassword $s 8
genPassword $s 12
genPassword $s 15
genPassword $s 20

#加密: ZjQzZTM0ZjlkZDcxNWYxMmUxMmIyMWIxNmZmNmQyNDEwZWE2MjFkNDIxZGMyNzAzYjA0YWI5N2EyZTE4NWM5Mgo=
#ZjQzZ_TM
#ZjQzZ_TM0Zjl
#ZjQzZ_TM0ZjlkZD
#ZjQzZ_TM0ZjlkZDcxNWY

