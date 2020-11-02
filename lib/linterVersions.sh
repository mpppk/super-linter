#!/usr/bin/env bash

BuildLinterVersions() {
  VERSION_FILE="${1}" && shift
  LINTER_ARRAY=("$@")

  debug "Building linter version file ${VERSION_FILE} for the following linters: ${LINTER_ARRAY[*]}..."

  ##########################################################
  # Go through the array of linters and print version info #
  ##########################################################
  for LINTER in "${LINTER_ARRAY[@]}"; do
    if [ -n "${LINTER}" ]; then
      ####################
      # Get the versions #
      ####################
      if [[ ${LINTER} == "arm-ttk" ]]; then
        # Need specific command for ARM
        mapfile -t GET_VERSION_CMD < <(grep -iE 'version' "/usr/bin/arm-ttk" | xargs 2>&1)
      elif [[ ${LINTER} == "protolint" ]] || [[ ${LINTER} == "editorconfig-checker" ]] || [[ ${LINTER} == "bash-exec" ]]; then
        # Need specific command for Protolint and editorconfig-checker
        mapfile -t GET_VERSION_CMD < <(echo "--version not supported")
      elif [[ ${LINTER} == "lintr" ]]; then
        # Need specific command for lintr (--slave is deprecated in R 4.0 and replaced by --no-echo)
        mapfile -t GET_VERSION_CMD < <(R --slave -e "r_ver <- R.Version()\$version.string; \
                    lintr_ver <- packageVersion('lintr'); \
                    glue::glue('lintr { lintr_ver } on { r_ver }')")
      elif [[ ${LINTER} == "lua" ]]; then
        # Semi standardversion command
        mapfile -t GET_VERSION_CMD < <("${LINTER}" -v 2>&1)
      elif [[ ${LINTER} == "terrascan" ]]; then
        mapfile -t GET_VERSION_CMD < <("${LINTER}" version 2>&1)
      elif [[ ${LINTER} == "checkstyle" ]]; then
        mapfile -t GET_VERSION_CMD < <("java -jar /usr/bin/${LINTER}" --version 2>&1)
      else
        # Standard version command
        mapfile -t GET_VERSION_CMD < <("${LINTER}" --version 2>&1)
      fi

      #######################
      # Load the error code #
      #######################
      ERROR_CODE=$?

      ##############################
      # Check the shell for errors #
      ##############################
      if [ ${ERROR_CODE} -ne 0 ] || [ -z "${GET_VERSION_CMD[*]}" ]; then
        WriteFile "${LINTER}" "Failed to get version info" "${VERSION_FILE}"
        fatal "[${LINTER}]: Failed to get version info for:"
      else
        ##########################
        # Print the version info #
        ##########################
        info "Successfully found version for ${F[W]}[${LINTER}]${F[B]}: ${F[W]}${GET_VERSION_CMD[*]}"
        WriteFile "${LINTER}" "${GET_VERSION_CMD[*]}" "${VERSION_FILE}"
      fi
    fi
  done
}

WriteFile() {
  ##############
  # Read Input #
  ##############
  LINTER="$1"     # Name of the linter
  VERSION="$2"    # Version returned from check
  VERSION_FILE=$3 # Version file path

  #################################
  # Write the data to output file #
  #################################
  echo "${LINTER}: ${VERSION}" >> "${VERSION_FILE}" 2>&1

  #######################
  # Load the error code #
  #######################
  ERROR_CODE=$?

  ##############################
  # Check the shell for errors #
  ##############################
  if [ $ERROR_CODE -ne 0 ]; then
    fatal "Failed to write data to file!"
  fi
}
