<?php

namespace AppBundle\Services;

/**
 * Description of ExecuteScriptService
 *
 * @author robin
 */
class ExecuteScriptService {
    
    private $scripts_path;
    private $render_script;
    private $template_html;
    private $emotes_script;
    
    
    public function __construct($scripts_path, $render_sript, $template_html, $emotes_script) {
        $this->scripts_path = $scripts_path;
        $this->render_script = $render_sript;
        $this->template_html = $template_html;
        $this->emotes_script = $emotes_script;
    }
    
    public function execute($sortby, $order, $blacklist_users_file, $whitelist_users_file, $list_emotes_filename) {
        chdir($_SERVER['DOCUMENT_ROOT'] . $this->scripts_path);
        $list_user_filename = tempnam('/tmp', 'users_list_');
        $string = shell_exec("./$this->render_script $this->template_html $this->emotes_script $sortby $order $blacklist_users_file $whitelist_users_file $list_user_filename $list_emotes_filename 2>&1");
        unlink($list_user_filename);
        return $string;
    }
    
}
