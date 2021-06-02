<?php

use Nette\Neon\Neon;
use Nette\Utils\Finder;
use Symfony\Component\Yaml;


include __DIR__ . '/vendor/autoload.php';

$return = 0;

foreach (Finder::findFiles('*.neon')->from('./out') as $file) {
	try {
		Neon::decode(file_get_contents($file->getPathname()));
	} catch (Nette\Neon\Exception $e) {
		echo $file->getPathname() . ': ' . $e->getMessage() . PHP_EOL;
		$return = 1;
	}
}

foreach (Finder::findFiles('*.yaml')->from('./out') as $file) {
	try {
		Yaml\Yaml::parse(file_get_contents($file->getPathname()), Yaml\Yaml::PARSE_EXCEPTION_ON_INVALID_TYPE);
	} catch (Yaml\Exception\ParseException $e) {
		echo $file->getPathname() . ': ' . $e->getMessage() . PHP_EOL;
		$return = 1;
	}
}

exit($return);
