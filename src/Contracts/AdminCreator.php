<?php

namespace CodeCorner\SetupWizard\Contracts;

interface AdminCreator
{
    /** Create (or update) the first admin from the validated form data and return the model. */
    public function create(array $data): mixed;
}
