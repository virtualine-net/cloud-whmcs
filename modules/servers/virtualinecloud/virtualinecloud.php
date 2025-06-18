<?php
if(!defined("WHMCS")) die("WHMCS is not installed. Please install WHMCS first.");

require_once __DIR__ . '/vendor/autoload.php';

use Illuminate\Database\Capsule\Manager as Capsule;
use Virtualine\VirtualineClient;

function virtualinecloud_MetaData(){
    return [
        "DisplayName" => "Virtualine Cloud",
        "APIVersion" => "1.1"
    ];
}

function virtualinecloud_TestConnection($params)
{
    try {
        $virtualClient = new VirtualineClient($params['serverpassword'], $params['serverusername']);
        $result = $virtualClient->testConnection();
        if ($result === false) {
            throw new Exception("Failed to connect to Virtualine API");
        }
        
        return [
            'success' => true,
            'message' => 'Connection to Virtualine API successful.'
        ];
    } catch (Exception $e) {
        logModuleCall(
            'virtualine',
            __FUNCTION__,
            $params,
            $e->getMessage(),
            $e->getTraceAsString()
        );
        return [
            'success' => false,
            'error' => 'Failed to connect to Virtualine API: ' . $e->getMessage()
        ];
    }
}

function virtualinecloud_ConfigOptions($params) {
    $productType = isset($params['producttype']) ? $params['producttype'] : '';
    $isAddon = isset($params['isAddon']) ? $params['isAddon'] : false;

    $serverParams = [];
    $requiredServerParams = ['serverid', 'serverhostname', 'serverusername', 'serverpassword'];
    
    foreach ($requiredServerParams as $param) {
        if (isset($params[$param]) && !empty($params[$param])) {
            $serverParams[$param] = $params[$param];
        }
    }

    return [
        "product_id" => [
            "FriendlyName" => "Virtualine Product",
            "Type" => "dropdown",
            "Options" => [],
            "Description" => "Select the Virtualine product to use for this service.",
            "Required" => true,
            "SimpleMode" => true,
            "Loader" => function ($serverParams) {
                try {
                    if (empty($serverParams['serverusername']) || empty($serverParams['serverpassword'])) {
                        throw new \WHMCS\Exception\Module\InvalidConfiguration("Server credentials not configured");
                    }

                    $virtualClient = new VirtualineClient($serverParams['serverpassword'], $serverParams['serverusername']);
                    $products = $virtualClient->getProducts();

                    if (empty($products)) {
                        return ['0' => 'No products found on Virtualine server'];
                    }

                    $productOptions = [];
                    foreach ($products as $product) {
                        if ($product['integration'] !== 'Diyovm') continue;
                        if (empty($product['customFields']) || !isset($product['customFields'])) {
                            $productOptions[$product['id']] = $product['name'] . ' (ID: ' . $product['id'] . ')';
                        }
                    }

                    if (empty($productOptions)) {
                        return ['0' => 'No suitable products found (products with custom fields are excluded)'];
                    }

                    return $productOptions;

                } catch (\WHMCS\Exception\Module\InvalidConfiguration $e) {
                    logModuleCall(
                        'virtualine',
                        __FUNCTION__,
                        $serverParams,
                        $e->getMessage(),
                        $e->getTraceAsString()
                    );
                    return ['0' => 'Failed to load products: ' . $e->getMessage()];
                } catch (Exception $e) {
                    logModuleCall(
                        'virtualine',
                        __FUNCTION__,
                        $serverParams,
                        $e->getMessage(),
                        $e->getTraceAsString()
                    );
                    return ['0' => 'Failed to load products: ' . $e->getMessage()];
                }
            }
        ],
        "os_config_option" => [
            "FriendlyName" => "Operating System Config Option",
            "Type" => "dropdown",
            "Options" => [],
            "Description" => "Select the operating system configuration option for this service.",
            "Required" => true,
            "SimpleMode" => true,
            "Loader" => function ($serverParams) {
                try {
                    $productId = isset($_POST["id"]) && is_numeric($_POST["id"]) ? (int)$_POST["id"] : null;

                    if (!$productId) {
                        return ['0' => 'No product selected'];
                    }

                    $product = Capsule::table("tblproducts")
                        ->where("id", $productId)
                        ->first();

                    if (!$product) {
                        return ['0' => 'Product not found'];
                    }

                    $productconfigs = Capsule::table("tblproductconfiglinks")
                        ->select("gid")
                        ->where("pid", $product->id)
                        ->get();
                    
                    if ($productconfigs->isEmpty()) {
                        return ["0" => "No configuration options found"];
                    }

                    $gidList = $productconfigs->pluck('gid')->toArray();

                    if (empty($gidList)) {
                        return ["0" => "No configuration options found"];
                    }

                    $productconfigoptions = Capsule::table("tblproductconfigoptions")
                        ->whereIn("gid", $gidList)
                        ->orderBy('optionname')
                        ->get();

                    $productoptions = [
                        "0" => "No configuration selected"
                    ];

                    if (!$productconfigoptions->isEmpty()) {
                        foreach ($productconfigoptions as $config) {
                            if (isset($config->id) && isset($config->optionname) && !empty(trim($config->optionname))) {
                                $productoptions[(int)$config->id] = htmlspecialchars(trim($config->optionname), ENT_QUOTES, 'UTF-8');
                            }
                        }
                    }

                    return $productoptions;

                } catch (Exception $e) {
                    logModuleCall(
                        'virtualine',
                        __FUNCTION__,
                        $serverParams,
                        $e->getMessage(),
                        $e->getTraceAsString()
                    );
                    return ['0' => 'Failed to load OS config options: ' . $e->getMessage()];
                }
            }
        ]
    ];
}

function virtualinecloud_CreateAccount($params) {
    try {
        $virtualClient = new VirtualineClient($params['serverpassword'], $params['serverusername']);

        $os_option = Capsule::table("tblproductconfigoptions")
            ->select("id", "optionname")
            ->where("id", $params["configoption2"])
            ->first();

        if (!$os_option) {
            return "Operating system configuration not found";
        }

        $billingcycle = $params['model']->billingCycle;
        $cycle = "monthly";
        switch ($billingcycle) {
            case 'Quarterly':
                $cycle = "quarterly";
                break;
            case 'Semi-Annually':
                $cycle = "semi-annually";
                break;
            case 'Annually':
                $cycle = "annually";
                break;
            case 'Biennially':
                $cycle = "biennially";
                break;
            case 'Triennially':
                $cycle = "triennially";
                break;
            default:
                $cycle = "monthly";
                break;
        }

        $productId = $params['configoption1'];
        $result = $virtualClient->createService($productId, [
            'cycle' => $cycle,
            'hostname' => "service.virtualine.net",
            'username' => "root",
            'password' => $params["password"],
            'nsprefix[]' => 'ns1',
            'nsprefix[]' => 'ns2',
            'configurations[Operating System]' => $params["configoptions"][$os_option->optionname]
        ]);

        if ($result === false) {
            return "Failed to create service on Virtualine";
        }

        $dataToUpdate = [
            "username" => $result["data"]["service"]["username"],
            "password" => $params["password"],
            "dedicatedip" => $result["data"]["service"]['dedicatedip'],
            "assignedips" => $result["data"]["service"]['assignedips'],
            "domain" => $result["data"]["service"]['domain'],
            "service_id" => $result["data"]["serviceId"]
        ];

        $params["model"]->serviceProperties->save($dataToUpdate);

        return "success";
    } catch (Exception $e) {
        logModuleCall(
            'virtualine',
            __FUNCTION__,
            $params,
            $e->getMessage(),
            $e->getTraceAsString()
        );
        return "Failed to create account: " . $e->getMessage();
    }
}

function virtualinecloud_Renew($params)
{
    try {
        $virtualClient = new VirtualineClient($params['serverpassword'], $params['serverusername']);
        $serviceId = $params["customfields"]["service_id"];

        // Renew the service
        $result = $virtualClient->renew($serviceId);

        if ($result === false) {
            return "Failed to renew service on Virtualine";
        }

        return $result['result'] === "success" ? "success" : "Failed to renew service: " . $result['message'];
    } catch (Exception $e) {
        logModuleCall(
            'virtualine',
            __FUNCTION__,
            $params,
            $e->getMessage(),
            $e->getTraceAsString()
        );
        return "Failed to renew account: " . $e->getMessage();
    }
}

function virtualinecloud_SuspendAccount($params) {
    try {
        $virtualClient = new VirtualineClient($params['serverpassword'], $params['serverusername']);
        $result = $virtualClient->suspend($params["customfields"]["service_id"]);

        if ($result === false) {
            return "Failed to suspend service on Virtualine";
        }

        return "success";
    } catch (Exception $e) {
        logModuleCall(
            'virtualine',
            __FUNCTION__,
            $params,
            $e->getMessage(),
            $e->getTraceAsString()
        );
        return "Failed to suspend account: " . $e->getMessage();
    }
}

function virtualinecloud_UnsuspendAccount($params) {
    try {
        $virtualClient = new VirtualineClient($params['serverpassword'], $params['serverusername']);
        $result = $virtualClient->unsuspend($params["customfields"]["service_id"]);

        if ($result === false) {
            return "Failed to unsuspend service on Virtualine";
        }

        return "success";
    } catch (Exception $e) {
        logModuleCall(
            'virtualine',
            __FUNCTION__,
            $params,
            $e->getMessage(),
            $e->getTraceAsString()
        );
        return "Failed to unsuspend account: " . $e->getMessage();
    }
}

function virtualinecloud_TerminateAccount($params) {
    try {
        $virtualClient = new VirtualineClient($params['serverpassword'], $params['serverusername']);
        $result = $virtualClient->terminate($params["customfields"]["service_id"]);

        if ($result === false) {
            return "Failed to terminate service on Virtualine";
        }

        return "success";
    } catch (Exception $e) {
        logModuleCall(
            'virtualine',
            __FUNCTION__,
            $params,
            $e->getMessage(),
            $e->getTraceAsString()
        );
        return "Failed to terminate account: " . $e->getMessage();
    }
}

function virtualinecloud_ClientArea($params) {
    try {
        $virtualClient = new VirtualineClient($params['serverpassword'], $params['serverusername']);
        $serviceId = $params["customfields"]["service_id"];

        // Handle actions
        $actionMessage = '';
        if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['customAction'])) {
            switch ($_POST['customAction']) {
                case 'checkStatus':
                    $info = $virtualClient->getInfo($serviceId);
                    if (empty($info)) {
                        exit(json_encode([
                            'result' => 'error',
                            'message' => 'Failed to fetch service information'
                        ]));
                    }

                    if ($info['success']) {
                        exit(json_encode([
                            'result' => 'success'
                        ]));
                    }

                    exit(json_encode([
                        'result' => 'pending',
                        'message' => $info['warning'] ?? 'Installation in progress...',
                        'progress' => $info['progress'] ?? 0
                    ]));
                    break;

                case 'start':
                    $result = $virtualClient->start($serviceId);
                    $actionMessage = $result !== false ? 'Server started successfully.' : 'Failed to start server.';
                    break;
                case 'stop':
                    $result = $virtualClient->stop($serviceId);
                    $actionMessage = $result !== false ? 'Server stopped successfully.' : 'Failed to stop server.';
                    break;
                case 'reboot':
                    $result = $virtualClient->reboot($serviceId);
                    $actionMessage = $result !== false ? 'Server rebooted successfully.' : 'Failed to reboot server.';
                    break;
                case 'details':
                    $serviceDetails = $virtualClient->getServiceDetails($serviceId);
                    if ($serviceDetails) {
                        exit(json_encode([
                            'result' => 'success',
                            'data' => $serviceDetails,
                            'timestamp' => date('Y-m-d H:i:s')
                        ]));
                    }
                    exit(json_encode([
                        'result' => 'error',
                        'message' => 'Failed to fetch service details'
                    ]));
                    break;
                case 'reinstall':
                    $templateId = isset($_POST['osTemplate']) ? $_POST['osTemplate'] : '';
                    $reinstallPassword = isset($_POST['reinstallPassword']) ? $_POST['reinstallPassword'] : '';
                    if ($templateId && $reinstallPassword) {
                        $result = $virtualClient->reinstall($serviceId, $templateId, $reinstallPassword);
                        $actionMessage = $result !== false ? 'Reinstall started successfully.' : 'Failed to start reinstall.';
                        if ($result !== false) {
                            $params["model"]->serviceProperties->save([
                                "password" => $reinstallPassword,
                            ]);
                        }
                    } else {
                        $actionMessage = 'OS template and password are required.';
                    }
                    break;
            }
        }

        $info = $virtualClient->getInfo($serviceId);
        if (empty($info)) {
            return [
                'tabOverviewReplacementTemplate' => 'templates/installing.tpl',
                'vars' => [
                    'statusText' => 'Failed to fetch service information',
                    'serviceId' => $params['serviceid']
                ],
            ];
        }

        if (!$info['success']) {
            return [
                'tabOverviewReplacementTemplate' => 'templates/installing.tpl',
                'vars' => [
                    'statusText' => $info['warning'] ?? 'Installation in progress...',
                    'serviceId' => $params['serviceid']
                ],
            ];
        }

        $serviceDetails = $virtualClient->getServiceDetails($serviceId);
        $wmksUrl = $virtualClient->getWMKSUrl($serviceId);
        $osTemplates = $virtualClient->reinstallTemplates($serviceId);

        return [
            'tabOverviewReplacementTemplate' => 'templates/index.tpl',
            'vars' => [
                'service' => [
                    'product' => $params["model"]->product->name,
                    'username' => $params["username"],
                    'password' => $params["password"],
                    'amount' => $params["templatevars"]["recurringamount"]->toFull(),
                    'regdate' => date("Y-m-d H:i:s", strtotime($params["templatevars"]["regdate"])),
                    'nextduedate' => $params["templatevars"]["nextduedate"] ? date("Y-m-d H:i:s", strtotime($params["templatevars"]["nextduedate"])) : "--",
                ],
                'api' => $serviceDetails,
                'wmksUrl' => $wmksUrl,
                'osTemplates' => $osTemplates,
                'actionMessage' => $actionMessage,
            ],
        ];
    } catch (Exception $e) {
        logModuleCall(
            'virtualine',
            __FUNCTION__,
            $params,
            $e->getMessage(),
            $e->getTraceAsString()
        );
        return [
            'tabOverviewReplacementTemplate' => 'templates/installing.tpl',
            'vars' => [
                'statusText' => 'Service is temporarily unavailable. Please try again later.',
                'serviceId' => $params['serviceid']
            ],
        ];
    }
}