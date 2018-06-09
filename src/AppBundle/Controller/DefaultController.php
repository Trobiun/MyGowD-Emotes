<?php

namespace AppBundle\Controller;

use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\TextareaType;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;

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
                    'data' => 'asc'
                ))
                ->add('blacklist', TextareaType::class, array(
                    'label' => 'Blacklist utilisateurs',
                    'required' => false
                ))
                ->add('whitelist', TextareaType::class, array(
                    'label' => 'Whitelist utilisateurs',
                    'required' => false
                ))
                ->add('confirmer', SubmitType::class);
        
        $res = '';
        $form = $formBuilder->getForm();
        $form->handleRequest($request);
        if ($form->isSubmitted() && $form->isValid()) {
            $data = $form->getData();
            $sortby = $data['sortby'];
            $order = $data['order'];
            
            $blacklistFilename = tempnam('/tmp','blacklist_users_');
            $blacklistFileTemp = fopen($blacklistFilename,'w+');
            $this->string_users_to_file_users($data['blacklist'],$blacklistFilename);
            
            $whitelistFilename = tempnam('/tmp','whitelist_users_');
            $whitelistFileTemp = fopen($whitelistFilename,'w+');
            $this->string_users_to_file_users($data['whitelist'],$whitelistFilename);
            
            $renderService = $this->container->get('app.execute_script_service');
            $res = $renderService->execute($sortby, $order, $blacklistFilename, $whitelistFilename);
            
            fclose($blacklistFileTemp);
            fclose($whitelistFileTemp);
            unlink($blacklistFilename);
            unlink($whitelistFilename);
        }
        
        return $this->render('default/index.html.twig', array(
                    'form' => $form->createView(),
                    'res' => $res
        ));
//        return $this->render('default/index.html.twig', [
//                    'base_dir' => realpath($this->getParameter('kernel.project_dir')) . DIRECTORY_SEPARATOR,
//        ]);
    }
    
    private function string_users_to_file_users($list, $filename) {
        $str_users = str_replace(',', ' ', $list);
        $patterns = ['/[[:space:]]/m', '/^/m', '/$/m', '/<>/'];
        $replacements = [PHP_EOL, '<', '>', ''];

        $users_file_content = preg_replace($patterns, $replacements, $str_users);
        file_put_contents($filename, $users_file_content);
    }
    
}
