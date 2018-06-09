<?php

namespace AppBundle\Controller;

use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\TextareaType;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;
use Symfony\Component\Form\Extension\Core\Type\ResetType;

class DefaultController extends Controller {

    /**
     * @Route("/", name="homepage")
     */
    public function indexAction(Request $request) {
        $formBuilder = $this->createFormBuilder()
                ->add('sortby', ChoiceType::class, array(
                    'label' => 'Tri',
                    'expanded' => true,
                    'choices' => array(
                        'Utilisation' => 'numeric',
                        'Alphabétique' => 'alpha'
                    ),
                    'data' => 'numeric'
                ))
                ->add('order', ChoiceType::class, array(
                    'label' => 'Ordre',
                    'expanded' => true,
                    'choices' => array(
                        'Croissant' => 'asc',
                        'Décroissant' => 'dsc'
                    ),
                    'data' => 'dsc'
                ))
                ->add('blacklist', TextareaType::class, array(
                    'label' => 'Blacklist utilisateurs (à séparer par une espace ou virgule)',
                    'required' => false
                ))
                ->add('whitelist', TextareaType::class, array(
                    'label' => 'Whitelist utilisateurs (à séparer par une espace ou virgule)',
                    'required' => false
                ))
                ->add('emoticones', TextareaType::class, array(
                    'label' => 'Émoticones supplémentaires (à séparer par une espace ou virgule)',
                    'required' => false
                ))
                ->add('Réinitialiser', ResetType::class)
                ->add('confirmer', SubmitType::class);
        
        $res = '';
        $form = $formBuilder->getForm();
        $form->handleRequest($request);
        if ($form->isSubmitted() && $form->isValid()) {
            $data = $form->getData();
            $sortby = $data['sortby'];
            $order = $data['order'];
            
            $blacklistFilename = tempnam('/tmp','blacklist_users_');
            $this->string_users_to_file_users($data['blacklist'],$blacklistFilename);
            
            $whitelistFilename = tempnam('/tmp','whitelist_users_');
            $this->string_users_to_file_users($data['whitelist'],$whitelistFilename);
            
            $emoticonesFilename = tempnam('/tmp','emoticones_');
            $original_emotes_file = $_SERVER['DOCUMENT_ROOT'] . $this->container->getParameter('app.scripts_path') . '/' . $this->container->getParameter('app.emotes_list');
            $this->append_emoticones($original_emotes_file, $data['emoticones'], $emoticonesFilename);
            
            $renderService = $this->container->get('app.execute_script_service');
            $res = $renderService->execute($sortby, $order, $blacklistFilename, $whitelistFilename, $emoticonesFilename);
            
            unlink($blacklistFilename);
            unlink($whitelistFilename);
            unlink($emoticonesFilename);
        }
        
        return $this->render('default/index.html.twig', array(
                    'form' => $form->createView(),
                    'res' => $res
        ));
    }
    
    private function string_users_to_file_users($list, $filename) {
        $str_users = str_replace(',', ' ', $list);
        $patterns = ['/[[:space:]]/m', '/^/m', '/$/m', '/<>/'];
        $replacements = [PHP_EOL, '<', '>', ''];
        
        $users_file_content = preg_replace($patterns, $replacements, $str_users);
        file_put_contents($filename, $users_file_content);
    }
    
    private function append_emoticones($original_file, $emotes_added, $filename) {
        $original_emotes = file_get_contents($original_file);
        file_put_contents($filename, $original_emotes);
        
        $str_emotes_add = str_replace(',', ' ', $emotes_added);
        $emotes_to_add = preg_replace('/[[:space:]]/', PHP_EOL, $str_emotes_add);
        file_put_contents($filename, $emotes_to_add, FILE_APPEND);
    }
    
}
