#!/bin/bash

# Function to display success message in green color
print_success() {
    echo -e "\e[32m$1\e[0m" # \e[32m sets color to green, \e[0m resets color back to default
}

# Function to display error message in red color
print_error() {
    echo -e "\e[31m$1\e[0m" # \e[31m sets color to red, \e[0m resets color back to default
}

# Function to prompt for table name
prompt_for_table_name() {
    local table_name  # Variable to store table name entered by user
    
    # Path to your config.php file
    config_file="config.php"
    
    # Use grep to find the line containing DB_PREFIX and then extract the value with sed
    DB_PREFIX=$(grep "define('DB_PREFIX'" "$config_file" | sed -E "s/.*'([^']+)'.*/\1/")

    # Prompt user to enter table name (without prefix, it will be auto added)
    read -p "Enter table name (without prefix, it will be auto added): " table_name

    # Combine DB_PREFIX with user-provided table name
    table_name="${DB_PREFIX}${table_name}"

    # Echo the table name
    echo "$table_name"
}

# Function to generate SQL query based on table name and fields
generate_sql_query() {
    local table_name="$1"
    local sql_query=""
    
    # Start building SQL query with DB_PREFIX and combined table name
    sql_query+="CREATE TABLE IF NOT EXISTS \`$table_name\` (\n"

    # Prompt for fields and types until done
    while true; do
        read -p "Enter field name (or 'y' to finish): " field_name
        if [ "$field_name" == "y" ]; then
            break
        fi

        read -p "Enter field data type: " field_data_type

        # Append field and type to SQL query with proper newline and indentation
        sql_query+="  \`$field_name\` $field_data_type,"
    done

    # Remove the last comma and close the statement
    sql_query=$(echo -e "$sql_query" | sed '$ s/,$//')
    sql_query+=") ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;"

    # Echo the generated SQL query
    echo "$sql_query"
}

# Function to create directories and files for admin and catalog sides
create_extension() {
    local EXTENSION_NAME="$2"
    local EXTENSION_TYPE="$1"
    local CREATE_CATALOG="$3"
    local ADMIN_PATH="admin"
    local CATALOG_PATH="catalog"
    
    # Convert extension name to CamelCase for class name
    local CLASS_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')
    local CLASS_NAME_PATH=$(echo "$EXTENSION_TYPE" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')
    
    local LANGUAGE_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')
    
    # Create admin directories and files
    mkdir -p $ADMIN_PATH/controller/extension/$EXTENSION_TYPE
    cat <<EOF > $ADMIN_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php
<?php
class ControllerExtension${CLASS_NAME_PATH}${CLASS_NAME} extends Controller {
    private \$error = array();

	public function index() {
		\$this->load->language('extension/$EXTENSION_TYPE/$EXTENSION_NAME');

		\$this->document->setTitle(\$this->language->get('heading_title'));

		\$this->load->model('setting/setting');

		if ((\$this->request->server['REQUEST_METHOD'] == 'POST') && \$this->validate()) {
			\$this->model_setting_setting->editSetting('module_$EXTENSION_NAME', \$this->request->post);

			\$this->session->data['success'] = \$this->language->get('text_success');

			\$this->response->redirect(\$this->url->link('marketplace/extension', 'user_token=' . \$this->session->data['user_token'] . '&type=module', true));
		}

		if (isset(\$this->error['warning'])) {
			\$data['error_warning'] = \$this->error['warning'];
		} else {
			\$data['error_warning'] = '';
		}

		\$data['breadcrumbs'] = array();

		\$data['breadcrumbs'][] = array(
			'text' => \$this->language->get('text_home'),
			'href' => \$this->url->link('common/dashboard', 'user_token=' . \$this->session->data['user_token'], true)
		);

		\$data['breadcrumbs'][] = array(
			'text' => \$this->language->get('text_extension'),
			'href' => \$this->url->link('marketplace/extension', 'user_token=' . \$this->session->data['user_token'] . '&type=module', true)
		);

		\$data['breadcrumbs'][] = array(
			'text' => \$this->language->get('heading_title'),
			'href' => \$this->url->link('extension/$EXTENSION_TYPE/$EXTENSION_NAME', 'user_token=' . \$this->session->data['user_token'], true)
		);

		\$data['action'] = \$this->url->link('extension/$EXTENSION_TYPE/$EXTENSION_NAME', 'user_token=' . \$this->session->data['user_token'], true);

		\$data['cancel'] = \$this->url->link('marketplace/extension', 'user_token=' . \$this->session->data['user_token'] . '&type=module', true);

		if (isset(\$this->request->post['module_$EXTENSION_NAME_status'])) {
			\$data['module_$EXTENSION_NAME_status'] = \$this->request->post['module_$EXTENSION_NAME_status'];
		} else {
			\$data['module_$EXTENSION_NAME_status'] = \$this->config->get('module_$EXTENSION_NAME_status');
		}

		\$data['header'] = \$this->load->controller('common/header');
		\$data['column_left'] = \$this->load->controller('common/column_left');
		\$data['footer'] = \$this->load->controller('common/footer');

		\$this->response->setOutput(\$this->load->view('extension/$EXTENSION_TYPE/$EXTENSION_NAME', \$data));
	}

	protected function validate() {
		if (!\$this->user->hasPermission('modify', 'extension/$EXTENSION_TYPE/$EXTENSION_NAME')) {
			\$this->error['warning'] = \$this->language->get('error_permission');
		}

		return !\$this->error;
	}
EOF

# Add installation and uninstallation methods conditionally
if [ "$CREATE_CATALOG" == "-m" ]; then
cat <<EOF >> "$ADMIN_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
    public function install() {
        \$this->load->model('extension/$EXTENSION_TYPE/$EXTENSION_NAME');
        \$this->model_extension_${EXTENSION_TYPE}_${EXTENSION_NAME}->install();
    }

    public function uninstall() {
        \$this->load->model('extension/$EXTENSION_TYPE/$EXTENSION_NAME');
        \$this->model_extension_${EXTENSION_TYPE}_${EXTENSION_NAME}->uninstall();
    }
EOF
fi
cat <<EOF >> "$ADMIN_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
}
?>
EOF

if [ -f "$ADMIN_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php" ]; then
    print_success "Success:: $ADMIN_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
else
    print_error "Failed:: $ADMIN_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
fi

if [ "$CREATE_CATALOG" == "-m" ]; then

    # Call function to prompt for table name
    table_name=$(prompt_for_table_name)

    # Call function to generate SQL query based on the table name
    sql_query=$(generate_sql_query "$table_name")

    mkdir -p $ADMIN_PATH/controller/extension/$EXTENSION_TYPE
    cat <<EOF > $ADMIN_PATH/model/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php
<?php
class ModelExtension${CLASS_NAME_PATH}${CLASS_NAME} extends Model {
    public function install() {
        // Your installation code here

        // Read the generated SQL query
        \$sql = "$sql_query";
        // Execute SQL query to create table
        \$this->db->query(\$sql);
    }

    public function uninstall() {
        // Your uninstallation code here
        \$this->db->query("DROP TABLE IF EXISTS \`$table_name\`;");
    }
}
EOF

fi

if [ -f "$ADMIN_PATH/model/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php" ]; then
    print_success "Success:: $ADMIN_PATH/model/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
else
    print_error "Failed:: $ADMIN_PATH/model/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
fi
    cat <<EOF > $ADMIN_PATH/language/en-gb/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php
<?php
// Heading
\$_['heading_title'] = '$LANGUAGE_NAME';

// Text
\$_['text_extension']   = 'Extensions';
\$_['text_success']     = 'Success: You have modified ${LANGUAGE_NAME} ${EXTENSION_TYPE}!';
\$_['text_edit']        = 'Edit ${LANGUAGE_NAME} ${EXTENSION_TYPE}';

// Entry
\$_['entry_status']     = 'Status';

// Error
\$_['error_permission'] = 'Warning: You do not have permission to modify ${LANGUAGE_NAME} ${EXTENSION_TYPE}!';
?>
EOF

if [ -f "$ADMIN_PATH/language/en-gb/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php" ]; then
    print_success "Success:: $ADMIN_PATH/language/en-gb/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
else
    print_error "Failed:: $ADMIN_PATH/language/en-gb/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
fi

    mkdir -p $ADMIN_PATH/view/template/extension/$EXTENSION_TYPE
    cat <<EOF > $ADMIN_PATH/view/template/extension/$EXTENSION_TYPE/$EXTENSION_NAME.twig
{{ header }}{{ column_left }}
<div id="content">
  <div class="page-header">
    <div class="container-fluid">
      <div class="pull-right">
        <button type="submit" form="form-module" data-toggle="tooltip" title="{{ button_save }}" class="btn btn-primary"><i class="fa fa-save"></i></button>
        <a href="{{ cancel }}" data-toggle="tooltip" title="{{ button_cancel }}" class="btn btn-default"><i class="fa fa-reply"></i></a></div>
      <h1>{{ heading_title }}</h1>
      <ul class="breadcrumb">
        {% for breadcrumb in breadcrumbs %}
        <li><a href="{{ breadcrumb.href }}">{{ breadcrumb.text }}</a></li>
        {% endfor %}
      </ul>
    </div>
  </div>
  <div class="container-fluid">
    {% if error_warning %}
    <div class="alert alert-danger alert-dismissible"><i class="fa fa-exclamation-circle"></i> {{ error_warning }}
      <button type="button" class="close" data-dismiss="alert">&times;</button>
    </div>
    {% endif %}
    <div class="panel panel-default">
      <div class="panel-heading">
        <h3 class="panel-title"><i class="fa fa-pencil"></i> {{ text_edit }}</h3>
      </div>
      <div class="panel-body">
        <form action="{{ action }}" method="post" enctype="multipart/form-data" id="form-module" class="form-horizontal">
          <div class="form-group">
            <label class="col-sm-2 control-label" for="input-status">{{ entry_status }}</label>
            <div class="col-sm-10">
              <select name="module_${EXTENSION_NAME}_status" id="input-status" class="form-control">
                {% if module_${EXTENSION_NAME}_status %}
                <option value="1" selected="selected">{{ text_enabled }}</option>
                <option value="0">{{ text_disabled }}</option>
                {% else %}
                <option value="1">{{ text_enabled }}</option>
                <option value="0" selected="selected">{{ text_disabled }}</option>
                {% endif %}
              </select>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>
{{ footer }}
EOF

if [ -f "$ADMIN_PATH/view/template/extension/$EXTENSION_TYPE/$EXTENSION_NAME.twig" ]; then
    print_success "Success:: $ADMIN_PATH/view/template/extension/$EXTENSION_TYPE/$EXTENSION_NAME.twig"
else
    print_error "Failed:: $ADMIN_PATH/view/template/extension/$EXTENSION_TYPE/$EXTENSION_NAME.twig"
fi

if [ "$CREATE_CATALOG" == '-c' ]; then
    # Create catalog directories and files
    mkdir -p $CATALOG_PATH/controller/extension/$EXTENSION_TYPE
    cat <<EOF > $CATALOG_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php
<?php
class ControllerExtension${CLASS_NAME_PATH}${CLASS_NAME} extends Controller {
    public function index() {
        \$this->load->language('extension/$EXTENSION_TYPE/$EXTENSION_NAME');
        
        \$data['heading_title'] = \$this->language->get('heading_title');
        \$data['dummy_data'] = 'Hello from catalog side of $EXTENSION_NAME extension!';
        
        \$this->response->setOutput(\$this->load->view('extension/$EXTENSION_TYPE/$EXTENSION_NAME', \$data));
    }
}
?>
EOF

if [ -f "$CATALOG_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php" ]; then
    print_success "Success:: $CATALOG_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
else
    print_error "Failed:: $CATALOG_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
fi

    cat <<EOF > $CATALOG_PATH/language/en-gb/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php
<?php
// Heading
\$_['heading_title'] = '$LANGUAGE_NAME Module';
?>
EOF
if [ -f "$CATALOG_PATH/language/en-gb/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php" ]; then
    print_success "Success:: $CATALOG_PATH/language/en-gb/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
else
    print_error "Failed:: $CATALOG_PATH/language/en-gb/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php"
fi
    mkdir -p $CATALOG_PATH/view/theme/default/template/extension/$EXTENSION_TYPE
    cat <<EOF > $CATALOG_PATH/view/theme/default/template/extension/$EXTENSION_TYPE/$EXTENSION_NAME.twig
<div class="well well-sm">
    <h3>{{ heading_title }}</h3>
    <p>{{ dummy_data }}</p>
</div>
EOF
if [ -f "$CATALOG_PATH/view/theme/default/template/extension/$EXTENSION_TYPE/$EXTENSION_NAME.twig" ]; then
    print_success "Success:: $CATALOG_PATH/view/theme/default/template/extension/$EXTENSION_TYPE/$EXTENSION_NAME.twig"
else
    print_error "Failed:: $CATALOG_PATH/view/theme/default/template/extension/$EXTENSION_TYPE/$EXTENSION_NAME.twig"
fi
fi
    # Check if file creation was successful
if [ -f "$ADMIN_PATH/controller/extension/$EXTENSION_TYPE/$EXTENSION_NAME.php" ]; then
    echo "OpenCart extension '$EXTENSION_NAME' created successfully."
else
    print_error "Failed to create extension $EXTENSION_NAME."
fi
}

# Function to check if Composer is installed
check_composer() {
    if ! command -v composer &> /dev/null; then
        echo "Composer is not installed or not in PATH."
        exit 1
    fi
}

# install validation library
install_validation_library() {
    check_composer
    
    composer require code-corner/validation:dev-master
}

# Function to install OpenCart dependencies
create_library() {
    if [ -z "$1" ]; then
        echo "Usage: opencart.sh create-library <path>"
        exit 1
    fi
    local EXTENSION_NAME="$1"
    
    # Replace underscores with spaces and convert to title case
    CLASS_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')
        
    # Path to your config.php file
    config_file="config.php"
    
    # Use grep to find the line containing DIR_SYSTEM and then extract the value with sed
    DIR_SYSTEM=$(grep "define('DIR_SYSTEM'" "$config_file" | sed -E "s/.*'([^']+)'.*/\1/")
    # Create catalog directories and files
    mkdir -p $DIR_SYSTEM/library/$EXTENSION_TYPE
    cat <<EOF > ${DIR_SYSTEM}library/$EXTENSION_NAME.php
<?php
class $CLASS_NAME {
    public function __construct(\$registry)
    {
        \$this->registry = \$registry;
        \$this->config     = \$registry->get('config');
        \$this->currency = \$registry->get('currency');
        \$this->cache         = \$registry->get('cache');
        \$this->db             = \$registry->get('db');
        \$this->request     = \$registry->get('request');
        \$this->session     = \$registry->get('session');
    }   
}
?>
EOF

# Check if file creation was successful
if [ -f "${DIR_SYSTEM}library/$EXTENSION_NAME.php" ]; then
    echo "OpenCart library '$EXTENSION_NAME' created successfully."
else
    print_error "Failed to create library $EXTENSION_NAME."
fi

}

# Function to install OpenCart dependencies
create_model() {
    if [ -z "$1" ]; then
        echo "Usage: opencart.sh create-model <path> <filename>"
        exit 1
    fi
    local EXTENSION_NAME="$2"
    local EXTENSION_TYPE="$1"

    # Extract substring after first /
    SUBSTRING="${EXTENSION_TYPE#*/}"

    # Replace all / with underscores
    CLEANED_EXTENSION_TYPE="${SUBSTRING//\//_}"
    
    # Replace underscores with spaces and convert to title case
    CLASS_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')

    EXTENSION_FINAL_CLASS=$(echo "$CLEANED_EXTENSION_TYPE" | sed -e 's/_/ /g' | awk '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1)) tolower(substr($i,2))}')

    mkdir -p $EXTENSION_TYPE
    cat <<EOF > ${EXTENSION_TYPE}/$EXTENSION_NAME.php
<?php
class $EXTENSION_FINAL_CLASS${CLASS_NAME} extends Model {
    
}
?>
EOF

# Check if file creation was successful
if [ -f "${EXTENSION_TYPE}/$EXTENSION_NAME.php" ]; then
    echo "OpenCart library '$EXTENSION_NAME' created successfully."
else
    print_error "Failed to create model $EXTENSION_NAME."
fi

}

# Function to install OpenCart dependencies
create_controller() {
    if [ -z "$1" ]; then
        echo "Usage: opencart.sh create-controller <path> <filename>"
        exit 1
    fi
    local EXTENSION_NAME="$2"
    local EXTENSION_TYPE="$1"

    # Extract substring after first /
    SUBSTRING="${EXTENSION_TYPE#*/}"

    # Replace all / with underscores
    CLEANED_EXTENSION_TYPE="${SUBSTRING//\//_}"
    
    # Replace underscores with spaces and convert to title case
    CLASS_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')

    EXTENSION_FINAL_CLASS=$(echo "$CLEANED_EXTENSION_TYPE" | sed -e 's/_/ /g' | awk '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1)) tolower(substr($i,2))}')

    # Create catalog directories and files
    mkdir -p $EXTENSION_TYPE
    cat <<EOF > ${EXTENSION_TYPE}/$EXTENSION_NAME.php
<?php
class $EXTENSION_FINAL_CLASS${CLASS_NAME} extends Controller {
    
}
?>
EOF

# Check if file creation was successful
if [ -f "${EXTENSION_TYPE}/$EXTENSION_NAME.php" ]; then
    echo "OpenCart library '$EXTENSION_NAME' created successfully."
else
    print_error "Failed to create controller $EXTENSION_NAME."
fi

}

# Function to install OpenCart dependencies
create_language() {
    if [ -z "$1" ]; then
        echo "Usage: opencart.sh create-language <path> <filename>"
        exit 1
    fi
    local EXTENSION_NAME="$2"
    local EXTENSION_TYPE="$1"

    # Extract substring after first /
    SUBSTRING="${EXTENSION_TYPE#*/}"

    # Replace all / with underscores
    CLEANED_EXTENSION_TYPE="${SUBSTRING//\//_}"
    
    # Replace underscores with spaces and convert to title case
    CLASS_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')

    EXTENSION_FINAL_CLASS=$(echo "$CLEANED_EXTENSION_TYPE" | sed -e 's/_/ /g' | awk '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1)) tolower(substr($i,2))}')

    # Create catalog directories and files
    mkdir -p $EXTENSION_TYPE
    cat <<EOF > ${EXTENSION_TYPE}/$EXTENSION_NAME.php
<?php
\$_['heading_title'] = 'Language';
?>
EOF

# Check if file creation was successful
if [ -f "${EXTENSION_TYPE}/$EXTENSION_NAME.php" ]; then
    echo "OpenCart language '$EXTENSION_NAME' created successfully."
else
    print_error "Failed to create language $EXTENSION_NAME."
fi

}

# Function to install OpenCart dependencies
create_view() {
    if [ -z "$1" ]; then
        echo "Usage: opencart.sh create-template <path> <filename>"
        exit 1
    fi
    local EXTENSION_NAME="$2"
    local EXTENSION_TYPE="$1"

    # Extract substring after first /
    SUBSTRING="${EXTENSION_TYPE#*/}"

    # Replace all / with underscores
    CLEANED_EXTENSION_TYPE="${SUBSTRING//\//_}"
    
    # Replace underscores with spaces and convert to title case
    CLASS_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')

    EXTENSION_FINAL_CLASS=$(echo "$CLEANED_EXTENSION_TYPE" | sed -e 's/_/ /g' | awk '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1)) tolower(substr($i,2))}')

    # Create catalog directories and files
    mkdir -p $EXTENSION_TYPE
    cat <<EOF > ${EXTENSION_TYPE}/$EXTENSION_NAME.twig
{{ header }}{{ column_left }}
<div id="content">
  <div class="page-header">
    <div class="container-fluid">
      <div class="pull-right">
        <button type="submit" form="form-module" data-toggle="tooltip" title="{{ button_save }}" class="btn btn-primary"><i class="fa fa-save"></i></button>
        <a href="{{ cancel }}" data-toggle="tooltip" title="{{ button_cancel }}" class="btn btn-default"><i class="fa fa-reply"></i></a></div>
      <h1>{{ heading_title }}</h1>
      <ul class="breadcrumb">
        {% for breadcrumb in breadcrumbs %}
        <li><a href="{{ breadcrumb.href }}">{{ breadcrumb.text }}</a></li>
        {% endfor %}
      </ul>
    </div>
  </div>
  <div class="container-fluid">
    {% if error_warning %}
    <div class="alert alert-danger alert-dismissible"><i class="fa fa-exclamation-circle"></i> {{ error_warning }}
      <button type="button" class="close" data-dismiss="alert">&times;</button>
    </div>
    {% endif %}
    <div class="panel panel-default">
      <div class="panel-heading">
        <h3 class="panel-title"><i class="fa fa-pencil"></i> {{ text_edit }}</h3>
      </div>
      <div class="panel-body">
        <form action="{{ action }}" method="post" enctype="multipart/form-data" id="form-module" class="form-horizontal">
          
        </form>
      </div>
    </div>
  </div>
</div>
{{ footer }}
EOF

# Check if file creation was successful
if [ -f "${EXTENSION_TYPE}/$EXTENSION_NAME.twig" ]; then
    echo "OpenCart template '$EXTENSION_NAME' created successfully."
else
    print_error "Failed to create template $EXTENSION_NAME."
fi

}

create_ocmod() {
     if [ -z "$1" ]; then
        echo "Usage: opencart.sh create-ocmod <name> <zip>"
        exit 1
    fi
    local EXTENSION_NAME="$1"
    local EXTENSION_TYPE="$2"

    # Extract substring after first /
    SUBSTRING="${EXTENSION_NAME#*/}"

    # Replace all / with underscores
    CLEANED_EXTENSION_TYPE="${SUBSTRING//\//_}"
    
    # Replace underscores with spaces and convert to title case
    # CLASS_NAME=$(echo "$EXTENSION_NAME" | sed -e 's/_//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print $0}')

    # Path to your config.php file
    config_file="config.php"
    
    # Use grep to find the line containing DIR_SYSTEM and then extract the value with sed
    DIR_SYSTEM=$(grep "define('DIR_SYSTEM'" "$config_file" | sed -E "s/.*'([^']+)'.*/\1/")

    # EXTENSION_FINAL_CLASS=$(echo "$CLEANED_EXTENSION_TYPE" | sed -e 's/_/ /g' | awk '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1)) tolower(substr($i,2))}')

    # Create catalog directories and files
    # mkdir -p $EXTENSION_TYPE
    if [ "$2" = "-z" ]; then
    cat <<EOF > install.xml
    <?xml version="1.0" encoding="utf-8"?>
<modification>
  <name>$EXTENSION_NAME</name>
  <code>$CLEANED_EXTENSION_TYPE</code>
  <version>1.1</version>
  <author>Webkul Software Pvt. Ltd.</author>
  <link>http://www.webkul.com</link>
  <file path="file-path-here">
    <operation>
      <search regex="true">
        <![CDATA[ ]]>
      </search>
      <add position="replace">
        <![CDATA[ ]]>
      </add>
    </operation>
  </file>
</modification>

EOF
 # Create a zip file
    zip -r "${EXTENSION_NAME}.ocmod.zip" "install.xml"
    
    echo "Created install.xml and ${EXTENSION_NAME}.zip"
    else
    cat <<EOF > ${DIR_SYSTEM}$EXTENSION_NAME.ocmod.xml
    <?xml version="1.0" encoding="utf-8"?>
<modification>
  <name>$EXTENSION_NAME</name>
  <code>$CLEANED_EXTENSION_TYPE</code>
  <version>1.1</version>
  <author>Webkul Software Pvt. Ltd.</author>
  <link>http://www.webkul.com</link>
  <file path="file-path-here">
    <operation>
      <search regex="true">
        <![CDATA[ ]]>
      </search>
      <add position="replace">
        <![CDATA[ ]]>
      </add>
    </operation>
  </file>
</modification>

EOF
fi

# Check if file creation was successful
if [ -f "${DIR_SYSTEM}$EXTENSION_NAME.ocmod.xml" ]; then
    echo "OpenCart ocmod '$EXTENSION_NAME' created successfully."
else
    print_error "Failed to create ocmod $EXTENSION_NAME."
fi
}

# Check if extension name is provided as argument
# if [ $# -eq 0 ]; then
#     echo "Usage: $0 <extension_name>"
#     exit 1
# fi

# Handle command line arguments
case "$1" in
    create-extension)
        shift
        # echo "Enter extension type?: "
        # read type
    
        if [[ ! "$1" =~ ^[a-zA-Z_]+$ ]]; then
            echo "Invalid: $1 extension type."
            exit 1
        fi

        # echo "Enter extension name?: "
        # read name

        if [[ ! "$2" =~ ^[a-zA-Z_]+$ ]]; then
            echo "Invalid: $2 extension name."
            exit 1
        fi

        # echo "Want to include catalog extension (y): "
        # read both

        # Call function to create extension with provided name
        create_extension "$1" "$2" "$3" "$4"
        ;;
    install-validation-library)
        shift
        install_validation_library
        ;;
    create-library)
        shift
        # echo "Enter library name? "
        # read name
    
        if [[ ! "$1" =~ ^[a-zA-Z_]+$ ]]; then
            echo "Invalid: $1 library name."
            exit 1
        fi
        create_library "$1"
        ;;
    create-model)
        shift
        # echo "Enter library name? "
        # read name
    
        if [[ ! "$1" =~ ^[a-zA-Z_/]+$ ]]; then
            echo "Invalid: $1 model path."
            exit 1
        fi

        if [[ ! "$2" =~ ^[a-zA-Z_]+$ ]]; then
            echo "Invalid: $2 model name."
            exit 1
        fi
        create_model "$1" "$2"
        ;;
    create-controller)
        shift
        if [[ ! "$1" =~ ^[a-zA-Z_/]+$ ]]; then
            echo "Invalid: $1 controller path."
            exit 1
        fi

        if [[ ! "$2" =~ ^[a-zA-Z_]+$ ]]; then
            echo "Invalid: $2 controller name."
            exit 1
        fi
        create_controller "$1" "$2"
        ;;
    create-language)
        shift
        if [[ ! "$1" =~ ^[a-zA-Z_/-]+$ ]]; then
            echo "Invalid: $1 language path."
            exit 1
        fi

        if [[ ! "$2" =~ ^[a-zA-Z_]+$ ]]; then
            echo "Invalid: $2 language name."
            exit 1
        fi
        create_language "$1" "$2"
        ;;
    create-template)
        shift
        if [[ ! "$1" =~ ^[a-zA-Z_/]+$ ]]; then
            echo "Invalid: $1 template path."
            exit 1
        fi

        if [[ ! "$2" =~ ^[a-zA-Z_]+$ ]]; then
            echo "Invalid: $2 template name."
            exit 1
        fi
        create_view "$1" "$2"
        ;;
    create-ocmod)
        shift
        if [[ ! "$1" =~ ^[a-zA-Z_]+$ ]]; then
            echo "Invalid: $1 xml name."
            exit 1
        fi
        create_ocmod "$1" "$2"
        ;;
    *)
        echo "Usage: opencart.sh {create-extension <type> <name> -c <catalog>|install-validation-library|create-controller <path> <name>|create-language <path> <name>|create-template <path> <name>|create-model <path> <name>|create-library <path> <name>|create-ocmod <name> -z <zip>}"
        exit 1
        ;;
esac
