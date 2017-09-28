#!/usr/bin/env bash

# DEPRECATED, use vagrantcloud

#set -eux

function die_var_unset {
	echo "ERROR: Variable '$1' is required to be set. Please edit $0 and set."
	exit 1
}

[ -f sh_vars ] || { echo "User variables file 'sh_vars' not found."; exit 1; }

source sh_vars

[ -z "$dist_name" ] && die_var_unset "dist_name"
[ -z "$dist_vers" ] && die_var_unset "dist_vers"
[ -z "$dist_arch" ] && die_var_unset "dist_arch"
[ -z "$build_type" ] && die_var_unset "build_type"
[ -z "$ATLAS_USER_NAME" ] && die_var_unset "ATLAS_USER_NAME"
[ -z "$ATLAS_BOX_NAME" ] && ATLAS_BOX_NAME="${dist_name}-${dist_vers}-${dist_arch}"

template_name="${ATLAS_BOX_NAME}.json"

if [ ! -f $template_name ]; then
		echo "No template '$template_name' found!"
		echo "Creating skeleton, edit and run $0 again."
		if [ -f skeltempl.json ]; then
			mv skeltempl.json $template_name
            [ $? -eq 0 ] || { echo "Unable to 'mv skeltempl.json $template_name'."; exit 3; }
		else
			curl -sSo $template_name "https://raw.githubusercontent.com/maier/packer-templates/master/skel/skeltempl.json"
            [ $? -eq 0 ] || { echo "Unable retrieve 'skeltempl.json' from github repository."; exit 3; }
		fi
		exit 2
fi

case $build_type in
remote)
    echo "Pushing $template_name to Atlas for remote build. (and making it public)"
    packer push $template_name
    curl -H "X-Atlas-Token: $ATLAS_TOKEN" -X PUT -d box[is_private]='no' "https://atlas.hashicorp.com/api/v1/box/${ATLAS_USER_NAME}/${ATLAS_BOX_NAME}"
    ;;
local)
    export ATLAS_USER_NAME
    export ATLAS_BOX_NAME
    echo "Build box locally then push box to Atlas."
    packer build $template_name
    curl -H "X-Atlas-Token: $ATLAS_TOKEN" -X PUT -d box[is_private]='no' "https://atlas.hashicorp.com/api/v1/box/${ATLAS_USER_NAME}/${ATLAS_BOX_NAME}"
    unset ATLAS_BOX_NAME
    unset ATLAS_USER_NAME
    ;;
* )
    echo "Unknown atlas_build '$atlas_build'"
    exit 1
    ;;
esac

# END
