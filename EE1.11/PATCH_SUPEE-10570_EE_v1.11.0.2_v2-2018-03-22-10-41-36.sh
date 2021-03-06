#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-10570_v1.11.0.2 | EE_1.11.0.2 | v1 | 5508f64d2b00929ea5b050138ac80c40f647aea4 | Fri Mar 16 12:50:07 2018 +0200 | ee-1.11.0.2-dev

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 7ebbaa5..e6a1942 100644
--- app/Mage.php
+++ app/Mage.php
@@ -766,6 +766,7 @@ final class Mage
                 $message = print_r($message, true);
             }
 
+            $message = addcslashes($message, '<?');
             $loggers[$file]->log($message, $level);
         }
         catch (Exception $e) {
diff --git app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Hierarchy/Edit/Form.php app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Hierarchy/Edit/Form.php
index 0aa69dd..fd0bb1b 100644
--- app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Hierarchy/Edit/Form.php
+++ app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Hierarchy/Edit/Form.php
@@ -419,6 +419,7 @@ class Enterprise_Cms_Block_Adminhtml_Cms_Hierarchy_Edit_Form extends Mage_Adminh
             } else {
                 $nodes[$i]['meta_chapter_section'] = '';
             }
+            $nodes[$i]['label_esc'] = $this->escapeHtml($nodes[$i]['label']);
         }
 
         return Mage::helper('core')->jsonEncode($nodes);
diff --git app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Hierarchy/Widget/Chooser.php app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Hierarchy/Widget/Chooser.php
index 165a6f3..399ae11 100644
--- app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Hierarchy/Widget/Chooser.php
+++ app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Hierarchy/Widget/Chooser.php
@@ -108,7 +108,7 @@ class Enterprise_Cms_Block_Adminhtml_Cms_Hierarchy_Widget_Chooser extends Mage_A
                     var cls = nodes[i].page_id ? "cms_page" : "cms_node";
                     var node = new Ext.tree.TreeNode({
                         id: nodes[i].node_id,
-                        text: nodes[i].label,
+                        text: nodes[i].label.escapeHTML(),
                         cls: cls,
                         expanded: nodes[i].page_exists,
                         allowDrop: false,
diff --git app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php
index 8efbcf2..98a073e 100644
--- app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php
+++ app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php
@@ -89,7 +89,7 @@ class Enterprise_Cms_Block_Adminhtml_Cms_Page_Edit_Tab_Hierarchy
                     $node = array(
                         'node_id'               => $v['node_id'],
                         'parent_node_id'        => $v['parent_node_id'],
-                        'label'                 => $v['label'],
+                        'label'                 => $this->escapeHtml($v['label']),
                         'page_exists'           => $pageExists,
                         'page_id'               => $v['page_id'],
                         'current_page'          => (bool)$v['current_page']
@@ -109,7 +109,7 @@ class Enterprise_Cms_Block_Adminhtml_Cms_Page_Edit_Tab_Hierarchy
                     $node = array(
                         'node_id'               => $item->getId(),
                         'parent_node_id'        => $item->getParentNodeId(),
-                        'label'                 => $item->getLabel(),
+                        'label'                 => $this->escapeHtml($item->getLabel()),
                         'page_exists'           => (bool)$item->getPageExists(),
                         'page_id'               => $item->getPageId(),
                         'current_page'          => (bool)$item->getCurrentPage(),
@@ -177,7 +177,7 @@ class Enterprise_Cms_Block_Adminhtml_Cms_Page_Edit_Tab_Hierarchy
     public function getCurrentPageJson()
     {
         $data = array(
-            'label' => $this->quoteEscape($this->getPage()->getTitle()),
+            'label' => $this->escapeHtml($this->quoteEscape($this->getPage()->getTitle())),
             'id' => $this->getPage()->getId()
         );
 
diff --git app/code/core/Enterprise/Cms/Block/Hierarchy/Menu.php app/code/core/Enterprise/Cms/Block/Hierarchy/Menu.php
index b13a5b9..824e74d 100644
--- app/code/core/Enterprise/Cms/Block/Hierarchy/Menu.php
+++ app/code/core/Enterprise/Cms/Block/Hierarchy/Menu.php
@@ -194,7 +194,7 @@ class Enterprise_Cms_Block_Hierarchy_Menu extends Mage_Core_Block_Template
     {
         return array(
             '__ID__'    => $node->getId(),
-            '__LABEL__' => $node->getLabel(),
+            '__LABEL__' => $this->escapeHtml($node->getLabel()),
             '__HREF__'  => $node->getUrl()
         );
     }
diff --git app/code/core/Enterprise/Customer/Block/Adminhtml/Customer/Attribute/Edit/Tab/Main.php app/code/core/Enterprise/Customer/Block/Adminhtml/Customer/Attribute/Edit/Tab/Main.php
index 68e7a5f..86ec5cd 100644
--- app/code/core/Enterprise/Customer/Block/Adminhtml/Customer/Attribute/Edit/Tab/Main.php
+++ app/code/core/Enterprise/Customer/Block/Adminhtml/Customer/Attribute/Edit/Tab/Main.php
@@ -211,7 +211,7 @@ class Enterprise_Customer_Block_Adminhtml_Customer_Attribute_Edit_Tab_Main
             $inputTypeProp = $helper->getAttributeInputTypes($attribute->getFrontendInput());
 
             // input_filter
-            if ($inputTypeProp['filter_types']) {
+            if (isset($inputTypeProp['filter_types'])) {
                 $filterTypes = $helper->getAttributeFilterTypes();
                 $values = $form->getElement('input_filter')->getValues();
                 foreach ($inputTypeProp['filter_types'] as $filterTypeCode) {
@@ -221,7 +221,7 @@ class Enterprise_Customer_Block_Adminhtml_Customer_Attribute_Edit_Tab_Main
             }
 
             // input_validation getAttributeValidateFilters
-            if ($inputTypeProp['validate_filters']) {
+            if (isset($inputTypeProp['validate_filters'])) {
                 $filterTypes = $helper->getAttributeValidateFilters();
                 $values = $form->getElement('input_validation')->getValues();
                 foreach ($inputTypeProp['validate_filters'] as $filterTypeCode) {
@@ -236,7 +236,7 @@ class Enterprise_Customer_Block_Adminhtml_Customer_Attribute_Edit_Tab_Main
             $element = $form->getElement($elementId);
             $element->setScope($scope);
             if ($this->getAttributeObject()->getWebsite()->getId()) {
-                $element->setName('scope_' . $element->getName());
+                $element->setName('scope_' . Mage::helper('core')->escapeHtml($element->getName()));
             }
         }
 
diff --git app/code/core/Enterprise/GiftRegistry/Model/Observer.php app/code/core/Enterprise/GiftRegistry/Model/Observer.php
index 2376c37..2120254 100644
--- app/code/core/Enterprise/GiftRegistry/Model/Observer.php
+++ app/code/core/Enterprise/GiftRegistry/Model/Observer.php
@@ -99,7 +99,11 @@ class Enterprise_GiftRegistry_Model_Observer
                 ->loadByEntityItem($registryItemId);
             if ($model->getId()) {
                 $object->setId(Mage::helper('enterprise_giftregistry')->getAddressIdPrefix() . $model->getId());
-                $object->setCustomerId($this->_getSession()->getCustomer()->getId());
+                if (   !$model->getCustomerId()
+	                || ($model->getCustomerId() == $this->_getSession()->getCustomer()->getId())
+                ) {
+                    $object->setCustomerId($this->_getSession()->getCustomer()->getId());
+                }
                 $object->addData($model->exportAddress()->getData());
             }
         }
diff --git app/code/core/Enterprise/Reward/Block/Adminhtml/Customer/Edit/Tab/Reward/Management/Update.php app/code/core/Enterprise/Reward/Block/Adminhtml/Customer/Edit/Tab/Reward/Management/Update.php
index 10a5837..4d30704 100644
--- app/code/core/Enterprise/Reward/Block/Adminhtml/Customer/Edit/Tab/Reward/Management/Update.php
+++ app/code/core/Enterprise/Reward/Block/Adminhtml/Customer/Edit/Tab/Reward/Management/Update.php
@@ -125,7 +125,7 @@ class Enterprise_Reward_Block_Adminhtml_Customer_Edit_Tab_Reward_Management_Upda
         $nonEscapableNbspChar = html_entity_decode('&#160;', ENT_NOQUOTES, 'UTF-8');
         foreach ($stores as $websiteId => $website) {
             $values[] = array(
-                'label' => $website['label'],
+                'label' => $this->escapeHtml($website['label']),
                 'value' => array()
             );
             if (isset($website['children']) && is_array($website['children'])) {
@@ -139,7 +139,8 @@ class Enterprise_Reward_Block_Adminhtml_Customer_Edit_Tab_Reward_Management_Upda
                             );
                         }
                         $values[] = array(
-                            'label' => str_repeat($nonEscapableNbspChar, 4) . $group['label'],
+                            'label' => str_repeat($nonEscapableNbspChar, 4) .
+                                $this->escapeHtml($group['label']),
                             'value' => $options
                         );
                     }
diff --git app/code/core/Enterprise/Rma/Model/Shipping/Info.php app/code/core/Enterprise/Rma/Model/Shipping/Info.php
index ede6bb8..22a8aba 100644
--- app/code/core/Enterprise/Rma/Model/Shipping/Info.php
+++ app/code/core/Enterprise/Rma/Model/Shipping/Info.php
@@ -103,7 +103,7 @@ class Enterprise_Rma_Model_Shipping_Info extends Varien_Object
         /* @var $model Enterprise_Rma_Model_Rma */
         $model = Mage::getModel('enterprise_rma/rma');
         $rma = $model->load($this->getRmaId());
-        if (!$rma->getEntityId() || $this->getProtectCode() != $rma->getProtectCode()) {
+        if (!$rma->getEntityId() || $this->getProtectCode() !== $rma->getProtectCode()) {
             return false;
         }
         return $rma;
@@ -141,7 +141,7 @@ class Enterprise_Rma_Model_Shipping_Info extends Varien_Object
     public function getTrackingInfoByTrackId()
     {
         $track = Mage::getModel('enterprise_rma/shipping')->load($this->getTrackId());
-        if ($track->getId() && $this->getProtectCode() == $track->getProtectCode()) {
+        if ($track->getId() && $this->getProtectCode() === $track->getProtectCode()) {
             $this->_trackingInfo = array(array($track->getNumberDetail()));
         }
         return $this->_trackingInfo;
diff --git app/code/core/Enterprise/Staging/Block/Adminhtml/Backup/Grid.php app/code/core/Enterprise/Staging/Block/Adminhtml/Backup/Grid.php
index c26ad89..b3ee564 100644
--- app/code/core/Enterprise/Staging/Block/Adminhtml/Backup/Grid.php
+++ app/code/core/Enterprise/Staging/Block/Adminhtml/Backup/Grid.php
@@ -63,7 +63,8 @@ class Enterprise_Staging_Block_Adminhtml_Backup_Grid extends Mage_Adminhtml_Bloc
             'header'    => Mage::helper('enterprise_staging')->__('Website'),
             'index'     => 'name',
             'type'      => 'text',
-            'sortable'  => false
+            'sortable'  => false,
+            'escape'    => true,
         ));
 
         $this->addColumn('created_at', array(
@@ -133,7 +134,7 @@ class Enterprise_Staging_Block_Adminhtml_Backup_Grid extends Mage_Adminhtml_Bloc
         foreach($collection as $backup) {
             $websiteId   = $backup->getMasterWebsiteId();
             $websiteName = $backup->getMasterWebsiteName();
-            $websites[$websiteId] = $websiteName;
+            $websites[$websiteId] = $this->escapeHtml($websiteName);
         }
 
         return $websites;
diff --git app/code/core/Enterprise/Staging/Block/Adminhtml/Staging/Grid.php app/code/core/Enterprise/Staging/Block/Adminhtml/Staging/Grid.php
index d1306fd..3d7080f 100644
--- app/code/core/Enterprise/Staging/Block/Adminhtml/Staging/Grid.php
+++ app/code/core/Enterprise/Staging/Block/Adminhtml/Staging/Grid.php
@@ -92,6 +92,7 @@ class Enterprise_Staging_Block_Adminhtml_Staging_Grid extends Mage_Adminhtml_Blo
             'header'    => Mage::helper('enterprise_staging')->__('Website Name'),
             'index'     => 'name',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('base_url', array(
diff --git app/code/core/Mage/Admin/Helper/Data.php app/code/core/Mage/Admin/Helper/Data.php
new file mode 100644
index 0000000..c656292
--- /dev/null
+++ app/code/core/Mage/Admin/Helper/Data.php
@@ -0,0 +1,45 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+
+/**
+ * Admin Data Helper
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Admin_Helper_Data extends Mage_Core_Helper_Abstract
+{
+    /**
+     *  Get disallowed names for block
+     *
+     * @return bool
+     */
+    public function getDisallowedBlockNames()
+    {
+        return Mage::getResourceModel('admin/block')->getDisallowedBlockNames();
+    }
+}
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
index b33db1b..a672f4e 100644
--- app/code/core/Mage/Admin/Model/Block.php
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -53,6 +53,10 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
         if (!Zend_Validate::is($this->getBlockName(), 'NotEmpty')) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is required field.');
         }
+        $disallowedBlockNames = Mage::helper('admin')->getDisallowedBlockNames();
+        if (in_array($this->getBlockName(), $disallowedBlockNames)) {
+            $errors[] = Mage::helper('adminhtml')->__('Block Name is disallowed.');
+        }
         if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is incorrect.');
         }
diff --git app/code/core/Mage/Admin/Model/Resource/Block.php app/code/core/Mage/Admin/Model/Resource/Block.php
index 99b1c33..2e3e699 100644
--- app/code/core/Mage/Admin/Model/Resource/Block.php
+++ app/code/core/Mage/Admin/Model/Resource/Block.php
@@ -33,6 +33,14 @@
  */
 class Mage_Admin_Model_Resource_Block extends Mage_Core_Model_Resource_Db_Abstract
 {
+
+    /**
+     * Disallowed names for block
+     *
+     * @var array
+     */
+    protected $disallowedBlockNames = array('install/end');
+
     /**
      * Define main table
      *
@@ -41,4 +49,14 @@ class Mage_Admin_Model_Resource_Block extends Mage_Core_Model_Resource_Db_Abstra
     {
         $this->_init('admin/permission_block', 'block_id');
     }
+
+    /**
+     *  Get disallowed names for block
+     *
+     * @return array
+     */
+    public function getDisallowedBlockNames()
+    {
+        return $this->disallowedBlockNames;
+    }
 }
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 7720a09..62920b8 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -289,7 +289,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     /**
      * Login user
      *
-     * @param   string $login
+     * @param   string $username
      * @param   string $password
      * @return  Mage_Admin_Model_User
      */
@@ -297,6 +297,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     {
         if ($this->authenticate($username, $password)) {
             $this->getResource()->recordLogin($this);
+            Mage::getSingleton('core/session')->renewFormKey();
         }
         return $this;
     }
diff --git app/code/core/Mage/Admin/etc/config.xml app/code/core/Mage/Admin/etc/config.xml
index 4476621..ef4a326 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -62,6 +62,11 @@
                 </entities>
             </admin_resource>
         </models>
+        <helpers>
+            <admin>
+                <class>Mage_Admin_Helper</class>
+            </admin>
+        </helpers>
         <resources>
             <admin_setup>
                 <setup>
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Category/Edit/Form.php app/code/core/Mage/Adminhtml/Block/Catalog/Category/Edit/Form.php
index 475331a..e0b4507 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Category/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Category/Edit/Form.php
@@ -185,7 +185,7 @@ class Mage_Adminhtml_Block_Catalog_Category_Edit_Form extends Mage_Adminhtml_Blo
     {
         if ($this->hasStoreRootCategory()) {
             if ($this->getCategoryId()) {
-                return $this->getCategoryName();
+                return $this->escapeHtml($this->getCategoryName());
             } else {
                 $parentId = (int) $this->getRequest()->getParam('parent');
                 if ($parentId && ($parentId != Mage_Catalog_Model_Category::TREE_ROOT_ID)) {
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
index a042550..b5205ec 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
@@ -126,7 +126,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Grid extends Mage_Adminhtml_Block_Wid
         if ($store->getId()) {
             $this->addColumn('custom_name',
                 array(
-                    'header'=> Mage::helper('catalog')->__('Name in %s', $store->getName()),
+                    'header'=> Mage::helper('catalog')->__('Name in %s', $this->escapeHtml($store->getName())),
                     'index' => 'custom_name',
             ));
         }
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php
index de102ce..8a5c0e4 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php
@@ -38,10 +38,10 @@ class Mage_Adminhtml_Block_Newsletter_Template_Grid_Renderer_Sender extends Mage
     {
         $str = '';
         if($row->getTemplateSenderName()) {
-            $str .= htmlspecialchars($row->getTemplateSenderName()) . ' ';
+            $str .= $this->escapeHtml($row->getTemplateSenderName()) . ' ';
         }        
         if($row->getTemplateSenderEmail()) {
-            $str .= '[' . $row->getTemplateSenderEmail() . ']';
+            $str .= '[' .$this->escapeHtml($row->getTemplateSenderEmail()) . ']';
         }        
         if($str == '') {
             $str .= '---';
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
index 187c8a3..2f319ee 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
@@ -78,6 +78,7 @@ class Mage_Adminhtml_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Widget_
                 'type'      => 'store',
                 'store_view'=> true,
                 'display_deleted' => true,
+                'escape'  => true,
             ));
         }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Info.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Info.php
index 0e866e2..6cb8101 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Info.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Info.php
@@ -64,7 +64,7 @@ class Mage_Adminhtml_Block_Sales_Order_View_Info extends Mage_Adminhtml_Block_Sa
                 $store->getGroup()->getName(),
                 $store->getName()
             );
-            return implode('<br/>', $name);
+            return implode('<br/>', array_map(array($this, 'escapeHtml'), $name));
         }
         return null;
     }
diff --git app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php
index 656a6f1..4ff0c70 100644
--- app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php
@@ -241,7 +241,7 @@ class Mage_Adminhtml_Block_System_Store_Edit_Form extends Mage_Adminhtml_Block_W
                             $values[] = array('label'=>$group->getName(),'value'=>$group->getId());
                         }
                     }
-                    $groups[] = array('label'=>$website->getName(),'value'=>$values);
+                    $groups[] = array('label' => $this->escapeHtml($website->getName()), 'value' => $values);
                 }
                 $fieldset->addField('store_group_id', 'select', array(
                     'name'      => 'store[group_id]',
diff --git app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php
index 6cde6d4..d539293 100644
--- app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php
@@ -174,7 +174,7 @@ class Mage_Adminhtml_Block_Tag_Assigned_Grid extends Mage_Adminhtml_Block_Widget
         if ($store->getId()) {
             $this->addColumn('custom_name',
                 array(
-                    'header'=> Mage::helper('catalog')->__('Name in %s', $store->getName()),
+                    'header'=> Mage::helper('catalog')->__('Name in %s', $this->escapeHtml($store->getName())),
                     'index' => 'custom_name',
             ));
         }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php
index 423d0894..9d17bb0 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php
@@ -110,11 +110,11 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Store extends Mage_Adminh
         $data = $this->_getStoreModel()->getStoresStructure(false, $origStores);
 
         foreach ($data as $website) {
-            $out .= $website['label'] . '<br/>';
+            $out .= Mage::helper('core')->escapeHtml($website['label']) . '<br/>';
             foreach ($website['children'] as $group) {
-                $out .= str_repeat('&nbsp;', 3) . $group['label'] . '<br/>';
+                $out .= str_repeat('&nbsp;', 3) . Mage::helper('core')->escapeHtml($group['label']) . '<br/>';
                 foreach ($group['children'] as $store) {
-                    $out .= str_repeat('&nbsp;', 6) . $store['label'] . '<br/>';
+                    $out .= str_repeat('&nbsp;', 6) . Mage::helper('core')->escapeHtml($store['label']) . '<br/>';
                 }
             }
         }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php
index 612a835..10d6102 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php
@@ -289,9 +289,9 @@ class Mage_Adminhtml_Block_Widget_Tabs extends Mage_Adminhtml_Block_Widget
     public function getTabLabel($tab)
     {
         if ($tab instanceof Mage_Adminhtml_Block_Widget_Tab_Interface) {
-            return $tab->getTabLabel();
+            return $this->escapeHtml($tab->getTabLabel());
         }
-        return $tab->getLabel();
+        return $this->escapeHtml($tab->getLabel());
     }
 
     public function getTabContent($tab)
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index 82833c9..72bdc21 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -97,11 +97,9 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
             // use extra memory
             $fieldsetData = array();
             foreach ($groupData['fields'] as $field => $fieldData) {
+                $field = ltrim($field, '/');
                 $fieldsetData[$field] = (is_array($fieldData) && isset($fieldData['value']))
                     ? $fieldData['value'] : null;
-            }
-
-            foreach ($groupData['fields'] as $field => $fieldData) {
 
                 /**
                  * Get field backend model
diff --git app/code/core/Mage/Adminhtml/Model/System/Store.php app/code/core/Mage/Adminhtml/Model/System/Store.php
index 62c59b6..132de4d 100644
--- app/code/core/Mage/Adminhtml/Model/System/Store.php
+++ app/code/core/Mage/Adminhtml/Model/System/Store.php
@@ -151,7 +151,7 @@ class Mage_Adminhtml_Model_System_Store extends Varien_Object
                     }
                     if (!$websiteShow) {
                         $options[] = array(
-                            'label' => $website->getName(),
+                            'label' => Mage::helper('core')->escapeHtml($website->getName()),
                             'value' => array()
                         );
                         $websiteShow = true;
@@ -161,13 +161,15 @@ class Mage_Adminhtml_Model_System_Store extends Varien_Object
                         $values    = array();
                     }
                     $values[] = array(
-                        'label' => str_repeat($nonEscapableNbspChar, 4) . $store->getName(),
+                        'label' => str_repeat($nonEscapableNbspChar, 4) .
+                            Mage::helper('core')->escapeHtml($store->getName()),
                         'value' => $store->getId()
                     );
                 }
                 if ($groupShow) {
                     $options[] = array(
-                        'label' => str_repeat($nonEscapableNbspChar, 4) . $group->getName(),
+                        'label' => str_repeat($nonEscapableNbspChar, 4) .
+                            Mage::helper('core')->escapeHtml($group->getName()),
                         'value' => $values
                     );
                 }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index 3e94f2d..0731443 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -695,6 +695,16 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
                 $data['product']['stock_data']['use_config_manage_stock'] = 0;
             }
             $product = $this->_initProductSave();
+            // check sku attribute
+            $productSku = $product->getSku();
+            if ($productSku && $productSku != Mage::helper('core')->stripTags($productSku)) {
+                $this->_getSession()->addError($this->__('HTML tags are not allowed in SKU attribute.'));
+                $this->_redirect('*/*/edit', array(
+                    'id' => $productId,
+                    '_current' => true
+                ));
+                return;
+            }
 
             try {
                 $product->save();
diff --git app/code/core/Mage/Adminhtml/controllers/System/BackupController.php app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
index 7aeeaa2..1ab7571 100644
--- app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
@@ -34,6 +34,17 @@
 class Mage_Adminhtml_System_BackupController extends Mage_Adminhtml_Controller_Action
 {
     /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('create');
+        return parent::preDispatch();
+    }
+
+    /**
      * Backup list action
      */
     public function indexAction()
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 07fb895..cff2957 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -32,6 +32,7 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     const VALIDATOR_HTTP_X_FORVARDED_FOR_KEY    = 'http_x_forwarded_for';
     const VALIDATOR_HTTP_VIA_KEY                = 'http_via';
     const VALIDATOR_REMOTE_ADDR_KEY             = 'remote_addr';
+    const VALIDATOR_SESSION_EXPIRE_TIMESTAMP    = 'session_expire_timestamp';
 
     /**
      * Conigure and start session
@@ -318,6 +319,16 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     }
 
     /**
+     * Use session expire timestamp in validator key
+     *
+     * @return bool
+     */
+    public function useValidateSessionExpire()
+    {
+        return $this->getCookie()->getLifetime() > 0;
+    }
+
+    /**
      * Retrieve skip User Agent validation strings (Flash etc)
      *
      * @return array
@@ -380,6 +391,15 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
             return false;
         }
 
+        if ($this->useValidateSessionExpire()
+            && isset($sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP])
+            && $sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] < time() ) {
+            return false;
+        } else {
+            $this->_data[self::VALIDATOR_KEY][self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP]
+                = $validatorData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP];
+        }
+
         return true;
     }
 
@@ -413,6 +433,8 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
             $parts[self::VALIDATOR_HTTP_USER_AGENT_KEY] = (string)$_SERVER['HTTP_USER_AGENT'];
         }
 
+        $parts[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] = time() + $this->getCookie()->getLifetime();
+
         return $parts;
     }
 
diff --git app/code/core/Mage/Core/Model/Variable.php app/code/core/Mage/Core/Model/Variable.php
index 39e477a..2f79e53 100644
--- app/code/core/Mage/Core/Model/Variable.php
+++ app/code/core/Mage/Core/Model/Variable.php
@@ -141,7 +141,10 @@ class Mage_Core_Model_Variable extends Mage_Core_Model_Abstract
         foreach ($collection->toOptionArray() as $variable) {
             $variables[] = array(
                 'value' => '{{customVar code=' . $variable['value'] . '}}',
-                'label' => Mage::helper('core')->__('%s', $variable['label'])
+                'label' => Mage::helper('core')->__(
+                    '%s',
+                    Mage::helper('core')->escapeHtml($variable['label']
+                    ))
             );
         }
         if ($withGroup && $variables) {
diff --git app/code/core/Mage/Customer/etc/config.xml app/code/core/Mage/Customer/etc/config.xml
index 1ea51fc..204b346 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Customer>
-            <version>1.6.0.0</version>
+            <version>1.6.0.0.1.2</version>
         </Mage_Customer>
     </modules>
     <admin>
diff --git app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php
new file mode 100644
index 0000000..477b391
--- /dev/null
+++ app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php
@@ -0,0 +1,38 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Customer
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/** @var $installer Mage_Customer_Model_Entity_Setup */
+$installer = $this;
+$installer->startSetup();
+
+$installer->addAttribute('customer', 'password_created_at', array(
+    'label'    => 'Password created at',
+    'visible'  => false,
+    'required' => false,
+    'type'     => 'int'
+));
+
+$installer->endSetup();
diff --git app/code/core/Mage/Downloadable/etc/config.xml app/code/core/Mage/Downloadable/etc/config.xml
index 8cfa847..4ec34f9 100644
--- app/code/core/Mage/Downloadable/etc/config.xml
+++ app/code/core/Mage/Downloadable/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Downloadable>
-            <version>1.6.0.0.1</version>
+            <version>1.6.0.0.1.1.2</version>
         </Mage_Downloadable>
     </modules>
     <global>
@@ -380,7 +380,7 @@
                 <samples_title>Samples</samples_title>
                 <links_title>Links</links_title>
                 <links_target_new_window>1</links_target_new_window>
-                <content_disposition>inline</content_disposition>
+                <content_disposition>attachment</content_disposition>
                 <disable_guest_checkout>1</disable_guest_checkout>
             </downloadable>
         </catalog>
diff --git app/code/core/Mage/Downloadable/etc/system.xml app/code/core/Mage/Downloadable/etc/system.xml
index f755f81..78e9ea6 100644
--- app/code/core/Mage/Downloadable/etc/system.xml
+++ app/code/core/Mage/Downloadable/etc/system.xml
@@ -96,6 +96,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
+                            <comment>Using inline option could potentially lead to security issues.</comment>
                         </content_disposition>
                         <disable_guest_checkout translate="label comment">
                             <label>Disable Guest Checkout if Cart Contains Downloadable Items</label>
diff --git app/code/core/Mage/Downloadable/sql/downloadable_setup/upgrade-1.6.0.0.1.1.1-1.6.0.0.1.1.2.php app/code/core/Mage/Downloadable/sql/downloadable_setup/upgrade-1.6.0.0.1.1.1-1.6.0.0.1.1.2.php
new file mode 100644
index 0000000..e2e35ce
--- /dev/null
+++ app/code/core/Mage/Downloadable/sql/downloadable_setup/upgrade-1.6.0.0.1.1.1-1.6.0.0.1.1.2.php
@@ -0,0 +1,37 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Downloadable
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/** @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+$connection = $installer->getConnection();
+$connection->delete(
+    $this->getTable('core_config_data'),
+    $connection->prepareSqlCondition('path', array(
+        'like' => 'catalog/downloadable/content_disposition'
+    ))
+);
+$installer->endSetup();
diff --git app/code/core/Mage/ImportExport/Model/Import.php app/code/core/Mage/ImportExport/Model/Import.php
index 65bf9ba..e18c0b4 100644
--- app/code/core/Mage/ImportExport/Model/Import.php
+++ app/code/core/Mage/ImportExport/Model/Import.php
@@ -405,6 +405,10 @@ class Mage_ImportExport_Model_Import extends Mage_ImportExport_Model_Abstract
     public function uploadSource()
     {
         $entity    = $this->getEntity();
+        $validTypes = array_keys(Mage_ImportExport_Model_Config::getModels(self::CONFIG_KEY_ENTITIES));
+        if (!in_array($entity, $validTypes)) {
+            Mage::throwException(Mage::helper('importexport')->__('Incorrect entity type'));
+        }
         $uploader  = Mage::getModel('core/file_uploader', self::FIELD_NAME_SOURCE_FILE);
         $uploader->skipDbProcessing(true);
         $result    = $uploader->save(self::getWorkingDir());
diff --git app/code/core/Mage/ImportExport/Model/Import/Entity/Product.php app/code/core/Mage/ImportExport/Model/Import/Entity/Product.php
index f6f080a..ca4b170 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Product.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Product.php
@@ -91,6 +91,11 @@ class Mage_ImportExport_Model_Import_Entity_Product extends Mage_ImportExport_Mo
     const ERROR_SKU_NOT_FOUND_FOR_DELETE = 'skuNotFoundToDelete';
 
     /**
+     * Error - invalid product sku
+     */
+    const ERROR_INVALID_PRODUCT_SKU          = 'invalidSku';
+
+    /**
      * Pairs of attribute set ID-to-name.
      *
      * @var array
@@ -169,7 +174,8 @@ class Mage_ImportExport_Model_Import_Entity_Product extends Mage_ImportExport_Mo
         self::ERROR_INVALID_TIER_PRICE_SITE  => 'Tier Price data website is invalid',
         self::ERROR_INVALID_TIER_PRICE_GROUP => 'Tier Price customer group ID is invalid',
         self::ERROR_TIER_DATA_INCOMPLETE     => 'Tier Price data is incomplete',
-        self::ERROR_SKU_NOT_FOUND_FOR_DELETE => 'Product with specified SKU not found'
+        self::ERROR_SKU_NOT_FOUND_FOR_DELETE => 'Product with specified SKU not found',
+        self::ERROR_INVALID_PRODUCT_SKU          => 'Invalid value in SKU column. HTML tags are not allowed'
     );
 
     /**
@@ -574,6 +580,22 @@ class Mage_ImportExport_Model_Import_Entity_Product extends Mage_ImportExport_Mo
     }
 
     /**
+     * Check product sku data.
+     *
+     * @param array $rowData
+     * @param int $rowNum
+     * @return bool
+     */
+    protected function _isProductSkuValid(array $rowData, $rowNum)
+    {
+        if (isset($rowData['sku']) && $rowData['sku'] != Mage::helper('core')->stripTags($rowData['sku'])) {
+            $this->addRowError(self::ERROR_INVALID_PRODUCT_SKU, $rowNum);
+            return false;
+        }
+        return true;
+    }
+
+    /**
      * Custom options save.
      *
      * @return Mage_ImportExport_Model_Import_Entity_Product
@@ -1613,6 +1635,7 @@ class Mage_ImportExport_Model_Import_Entity_Product extends Mage_ImportExport_Mo
         $this->_isProductWebsiteValid($rowData, $rowNum);
         $this->_isProductCategoryValid($rowData, $rowNum);
         $this->_isTierPriceValid($rowData, $rowNum);
+        $this->_isProductSkuValid($rowData, $rowNum);
 
         if (self::SCOPE_DEFAULT == $rowScope) { // SKU is specified, row is SCOPE_DEFAULT, new product block begins
             $this->_processedEntitiesCount ++;
diff --git app/code/core/Mage/Shipping/Model/Info.php app/code/core/Mage/Shipping/Model/Info.php
index 7dbbe2d..31d6a44 100644
--- app/code/core/Mage/Shipping/Model/Info.php
+++ app/code/core/Mage/Shipping/Model/Info.php
@@ -79,7 +79,7 @@ class Mage_Shipping_Model_Info extends Varien_Object
     {
         $order = Mage::getModel('sales/order')->load($this->getOrderId());
 
-        if (!$order->getId() || $this->getProtectCode() != $order->getProtectCode()) {
+        if (!$order->getId() || $this->getProtectCode() !== $order->getProtectCode()) {
             return false;
         }
 
@@ -96,7 +96,7 @@ class Mage_Shipping_Model_Info extends Varien_Object
         /* @var $model Mage_Sales_Model_Order_Shipment */
         $model = Mage::getModel('sales/order_shipment');
         $ship = $model->load($this->getShipId());
-        if (!$ship->getEntityId() || $this->getProtectCode() != $ship->getProtectCode()) {
+        if (!$ship->getEntityId() || $this->getProtectCode() !== $ship->getProtectCode()) {
             return false;
         }
 
@@ -161,7 +161,7 @@ class Mage_Shipping_Model_Info extends Varien_Object
     public function getTrackingInfoByTrackId()
     {
         $track = Mage::getModel('sales/order_shipment_track')->load($this->getTrackId());
-        if ($track->getId() && $this->getProtectCode() == $track->getProtectCode()) {
+        if ($track->getId() && $this->getProtectCode() === $track->getProtectCode()) {
             $this->_trackingInfo = array(array($track->getNumberDetail()));
         }
         return $this->_trackingInfo;
diff --git app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
index accfc90..0e151de 100644
--- app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
+++ app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
@@ -161,7 +161,7 @@ class Mage_Widget_Adminhtml_Widget_InstanceController extends Mage_Adminhtml_Con
             ->setStoreIds($this->getRequest()->getPost('store_ids', array(0)))
             ->setSortOrder($this->getRequest()->getPost('sort_order', 0))
             ->setPageGroups($this->getRequest()->getPost('widget_instance'))
-            ->setWidgetParameters($this->getRequest()->getPost('parameters'));
+            ->setWidgetParameters($this->_prepareParameters());
         try {
             $widgetInstance->save();
             $this->_getSession()->addSuccess(
@@ -290,4 +290,20 @@ class Mage_Widget_Adminhtml_Widget_InstanceController extends Mage_Adminhtml_Con
     {
         return Mage::getSingleton('admin/session')->isAllowed('cms/widget_instance');
     }
+
+    /**
+     * Prepare widget parameters
+     *
+     * @return array
+     */
+    protected function _prepareParameters() {
+        $result = array();
+        $parameters = $this->getRequest()->getPost('parameters');
+        if(is_array($parameters) && count($parameters)) {
+            foreach ($parameters as $key => $value) {
+                $result[Mage::helper('core')->stripTags($key)] = $value;
+            }
+        }
+        return $result;
+    }
 }
diff --git app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml
index f03b6ec..be30a44 100644
--- app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml
@@ -115,6 +115,23 @@
                             cls:'folder'
                         });
 
+                        this.ge.completeEdit = function(remainVisible) {
+                            if (!this.editing) {
+                                return;
+                            }
+                            this.editNode.attributes.input = this.getValue();
+                            this.setValue(this.getValue().escapeHTML());
+                            return Ext.tree.TreeEditor.prototype.completeEdit.call(this, remainVisible);
+                        };
+
+                        this.ge.triggerEdit = function(node) {
+                            this.completeEdit();
+                            node.text = node.attributes.input;
+                            node.attributes.text = node.attributes.input;
+                            this.editNode = node;
+                            this.startEdit(node.ui.textNode, node.text);
+                        };
+
                         this.root.addListener('beforeinsert', editSet.leftBeforeInsert);
                         this.root.addListener('beforeappend', editSet.leftBeforeInsert);
 
@@ -161,7 +178,7 @@
                         for( i in rootNode.childNodes ) {
                             if(rootNode.childNodes[i].id) {
                                 var group = rootNode.childNodes[i];
-                                editSet.req.groups[gIterator] = new Array(group.id, group.attributes.text.strip(), (gIterator+1));
+                                editSet.req.groups[gIterator] = new Array(group.id, group.attributes.input.strip(), (gIterator+1));
                                 var iterator = 0
                                 for( j in group.childNodes ) {
                                     iterator ++;
@@ -194,6 +211,8 @@
                 if (!config) return null;
                 if (parent && config && config.length){
                     for (var i = 0; i < config.length; i++) {
+                        config[i].input = config[i].text;
+                        config[i].text = config[i].text.escapeHTML();
                         var node = new Ext.tree.TreeNode(config[i]);
                         parent.appendChild(node);
                         node.addListener('click', editSet.register);
@@ -295,6 +314,7 @@
 
                             var newNode = new Ext.tree.TreeNode({
                                     text : group_name.escapeHTML(),
+                                    input: group_name,
                                     cls : 'folder',
                                     allowDrop : true,
                                     allowDrag : true
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index ac500ac..2e1ab28 100644
--- app/design/adminhtml/default/default/template/customer/tab/view.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view.phtml
@@ -66,7 +66,7 @@ $createDateStore    = $this->getStoreCreateDate();
             <?php endif; ?>
             <tr>
                 <td><strong><?php echo $this->__('Account Created in:') ?></strong></td>
-                <td><?php echo $this->getCreatedInStore() ?></td>
+                <td><?php echo $this->escapeHtml($this->getCreatedInStore()); ?></td>
             </tr>
             <tr>
                 <td><strong><?php echo $this->__('Customer Group:') ?></strong></td>
diff --git app/design/adminhtml/default/default/template/customer/tab/view/sales.phtml app/design/adminhtml/default/default/template/customer/tab/view/sales.phtml
index eda33d7..bde06cc 100644
--- app/design/adminhtml/default/default/template/customer/tab/view/sales.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view/sales.phtml
@@ -53,18 +53,18 @@
                         <?php $_groupRow = false; ?>
                         <?php foreach ($_stores as $_row): ?>
                         <?php if ($_row->getStoreId() == 0): ?>
-                        <td colspan="3" class="label"><?php echo $_row->getStoreName() ?></td>
+                        <td colspan="3" class="label"><?php echo $this->escapeHtml($_row->getStoreName()); ?></td>
                         <?php else: ?>
                 <tr<?php echo ($_i++ % 2 ? ' class="even"' : '') ?>>
                         <?php if (!$_websiteRow): ?>
-                    <td rowspan="<?php echo $this->getWebsiteCount($_websiteId) ?>"><?php echo $_row->getWebsiteName() ?></td>
+                    <td rowspan="<?php echo $this->getWebsiteCount($_websiteId) ?>"><?php echo $this->escapeHtml($_row->getWebsiteName()); ?></td>
                             <?php $_websiteRow = true; ?>
                         <?php endif; ?>
                         <?php if (!$_groupRow): ?>
-                    <td rowspan="<?php echo count($_stores) ?>"><?php echo $_row->getGroupName() ?></td>
+                    <td rowspan="<?php echo count($_stores) ?>"><?php echo $this->escapeHtml($_row->getGroupName()); ?></td>
                             <?php $_groupRow = true; ?>
                         <?php endif; ?>
-                    <td class="label"><?php echo $_row->getStoreName() ?></td>
+                    <td class="label"><?php echo $this->escapeHtml($_row->getStoreName()); ?></td>
                         <?php endif; ?>
                     <td><?php echo $this->formatCurrency($_row->getLifetime(), $_row->getWebsiteId()) ?></td>
                     <td><?php echo $this->formatCurrency($_row->getAvgsale(), $_row->getWebsiteId()) ?></td>
diff --git app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml
index 4a1baa5..229c895 100644
--- app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml
@@ -34,14 +34,14 @@
             <?php foreach ($this->getStoreCollection($_group) as $_store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <option website="true" value="<?php echo $_website->getId() ?>"<?php if($this->getRequest()->getParam('website') == $_website->getId()): ?> selected="selected"<?php endif; ?>><?php echo $_website->getName() ?></option>
+                    <option website="true" value="<?php echo $_website->getId() ?>"<?php if($this->getRequest()->getParam('website') == $_website->getId()): ?> selected="selected"<?php endif; ?>><?php echo $this->escapeHtml($_website->getName()); ?></option>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <!--optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>"-->
-                    <option group="true" value="<?php echo $_group->getId() ?>"<?php if($this->getRequest()->getParam('group') == $_group->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?></option>
+                    <!--optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>"-->
+                    <option group="true" value="<?php echo $_group->getId() ?>"<?php if($this->getRequest()->getParam('group') == $_group->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?></option>
                 <?php endif; ?>
-                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 <!--</optgroup>-->
diff --git app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
index ad256c9..4375107 100644
--- app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
@@ -34,7 +34,7 @@
         <dl>
         <?php $_links = $this->getLinks(); ?>
         <?php $_isRequired = $this->getLinkSelectionRequired(); ?>
-            <dt><label<?php if ($_isRequired) echo ' class="required"' ?>><?php if ($_isRequired) echo '<em>*</em>' ?><?php echo $this->getLinksTitle() ?></label></dt>
+            <dt><label<?php if ($_isRequired) echo ' class="required"' ?>><?php if ($_isRequired) echo '<em>*</em>' ?><?php echo $this->escapeHtml($this->getLinksTitle()); ?></label></dt>
             <dd class="last">
                 <ul id="downloadable-links-list" class="options-list">
                 <?php foreach ($_links as $_link): ?>
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
index 8b24ab6..00a8500 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
@@ -39,7 +39,7 @@
             <td class="label"><label for="name"><?php echo Mage::helper('downloadable')->__('Title')?></label>
             </td>
             <td class="value">
-                <input type="text" class="input-text" id="downloadable_links_title" name="product[links_title]" value="<?php echo $_product->getId()?$_product->getLinksTitle():$this->getLinksTitle() ?>" <?php echo ($_product->getStoreId() && $this->getUsedDefault())?'disabled="disabled"':'' ?> />
+                <input type="text" class="input-text" id="downloadable_links_title" name="product[links_title]" value="<?php echo $_product->getId() ? $this->escapeHtml($_product->getLinksTitle()) : $this->escapeHtml($this->getLinksTitle()); ?>" <?php echo ($_product->getStoreId() && $this->getUsedDefault())?'disabled="disabled"':'' ?> />
             </td>
             <td class="scope-label"><?php if (!Mage::app()->isSingleStoreMode()): ?>[STORE VIEW]<?php endif; ?></td>
             <td class="value use-default">
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
index 0203828..ee1ab9b 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $_link->getLinkTitle() ?></dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
index d060eee..0bfb509 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $_link->getLinkTitle() ?> (<?php echo $_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('Unlimited') ?>)</dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
index 79e9774..248fc77 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $_link->getLinkTitle() ?> (<?php echo $_link->getNumberOfDownloadsUsed() . ' / ' . ($_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('U')) ?>)</dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/enterprise/cms/hierarchy/edit.phtml app/design/adminhtml/default/default/template/enterprise/cms/hierarchy/edit.phtml
index 4eb8b6d..68f29f3 100644
--- app/design/adminhtml/default/default/template/enterprise/cms/hierarchy/edit.phtml
+++ app/design/adminhtml/default/default/template/enterprise/cms/hierarchy/edit.phtml
@@ -108,7 +108,8 @@
 
                 var node = new Ext.tree.TreeNode({
                     id: this.nodes[i].node_id,
-                    text: this.nodes[i].label,
+                    text: this.nodes[i].label_esc,
+                    input: this.nodes[i].label,
                     page_id: this.nodes[i].page_id,
                     identifier: this.nodes[i].identifier,
                     cls: cssClass,
@@ -214,7 +215,7 @@
             }
 
             if (!hasPageId) {
-                $('node_label').value = node.text;
+                $('node_label').value = node.attributes.input;
                 $('node_identifier').value = node.attributes.identifier;
             } else {
                 $('node_label_text').innerHTML = this.getEditPageAnchorHtml(node.attributes.page_id, node.text);
@@ -269,7 +270,8 @@
                 }
                 rootNode.appendChild(new Ext.tree.TreeNode({
                     id: '_' + this.increment,
-                    text: label,
+                    text: label.escapeHTML(),
+                    input: label,
                     identifier: identifier,
                     page_id: page_id,
                     cls: 'cms_page',
@@ -296,7 +298,7 @@
                     node_id: node.id,
                     parent_node_id: node.parentNode.id == '_root' ? null : node.parentNode.id,
                     page_id: node.attributes.page_id,
-                    label: node.attributes.text,
+                    label: node.attributes.input,
                     identifier: node.attributes.identifier,
                     sort_order: node.parentNode.indexOf(node),
                     level: node.getDepth()
@@ -427,6 +429,7 @@
                 }
             }
 
+            var label = $('node_label').value;
             if (hasNodeId) {
                 var node_id = $('node_id').value;
                 var node = this.tree.getNodeById(node_id);
@@ -441,13 +444,15 @@
                 }
 
                 if (!hasPageId) {
-                    node.setText($('node_label').value);
+                    node.setText(label.escapeHTML());
                     node.attributes.identifier = identifier;
+                    node.attributes.input = label;
                 }
             } else {
                 var node = new Ext.tree.TreeNode({
                     id: '_' + this.increment,
-                    text: $('node_label').value,
+                    text: label.escapeHTML(),
+                    input: label,
                     identifier: $('node_identifier').value,
                     page_id: null,
                     cls: 'cms_node',
diff --git app/design/adminhtml/default/default/template/enterprise/cms/page/preview/store.phtml app/design/adminhtml/default/default/template/enterprise/cms/page/preview/store.phtml
index a3f8003..688a027 100644
--- app/design/adminhtml/default/default/template/enterprise/cms/page/preview/store.phtml
+++ app/design/adminhtml/default/default/template/enterprise/cms/page/preview/store.phtml
@@ -37,13 +37,13 @@
             <?php foreach ($this->getStores($group) as $store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <optgroup label="<?php echo $website->getName() ?>"></optgroup>
+                    <optgroup label="<?php echo $this->escapeHtml($website->getName()); ?>"></optgroup>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $group->getName() ?>">
+                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($group->getName()); ?>">
                 <?php endif; ?>
-                <option value="<?php echo $store->getId() ?>"<?php if($this->getStoreId() == $store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $store->getName() ?></option>
+                <option value="<?php echo $store->getId() ?>"<?php if($this->getStoreId() == $store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/enterprise/customer/website/switcher.phtml app/design/adminhtml/default/default/template/enterprise/customer/website/switcher.phtml
index 611385e..4eeb6c3 100644
--- app/design/adminhtml/default/default/template/enterprise/customer/website/switcher.phtml
+++ app/design/adminhtml/default/default/template/enterprise/customer/website/switcher.phtml
@@ -29,10 +29,10 @@
 <p class="switcher"><label for="website_switcher"><?php echo $this->__('Choose Website') ?>:</label>
 <select name="website_switcher" id="website_switcher" onchange="return switchWebsite(this);">
 <?php if ($this->hasDefaultOption()): ?>
-    <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+    <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
 <?php endif; ?>
     <?php foreach ($websites as $website): ?>
-        <option value="<?php echo $website->getId() ?>"<?php if ($this->getStoreId() == $website->getId()): ?> selected="selected"<?php endif; ?>><?php echo $website->getName() ?></option>
+        <option value="<?php echo $website->getId() ?>"<?php if ($this->getStoreId() == $website->getId()): ?> selected="selected"<?php endif; ?>><?php echo $this->escapeHtml($website->getName()); ?></option>
     <?php endforeach; ?>
 </select>
 </p>
diff --git app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
index b1b3a19..83b6909 100644
--- app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
+++ app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
@@ -78,11 +78,11 @@
             </tr>
             <tr>
                 <td class="label"><label><?php  echo $this->helper('enterprise_invitation')->__('Website'); ?></label></td>
-                <td><strong><?php echo $this->getWebsiteName() ?></strong></td>
+                <td><strong><?php echo $this->escapeHtml($this->getWebsiteName()); ?></strong></td>
             </tr>
             <tr>
                 <td class="label"><label><?php  echo $this->helper('enterprise_invitation')->__('Store View'); ?></label></td>
-                <td><strong><?php echo $this->getStoreName() ?></strong></td>
+                <td><strong><?php echo $this->escapeHtml($this->getStoreName()); ?></strong></td>
             </tr>
             <tr>
                 <td class="label"><label><?php  echo $this->helper('enterprise_invitation')->__('Invitee Group'); ?></label></td>
diff --git app/design/adminhtml/default/default/template/enterprise/staging/log/information/create.phtml app/design/adminhtml/default/default/template/enterprise/staging/log/information/create.phtml
index d9cb996..402c9dd 100644
--- app/design/adminhtml/default/default/template/enterprise/staging/log/information/create.phtml
+++ app/design/adminhtml/default/default/template/enterprise/staging/log/information/create.phtml
@@ -38,8 +38,8 @@
                 <div class="hor-scroll">
                     <table cellspacing="0" class="form-list">
                     <tr>
-                        <td><?php echo $this->getMasterWebsiteName() ?></td>
-                        <td>&nbsp;-&gt;&nbsp;<?php echo $this->getStagingWebsiteName() ?></td>
+                        <td><?php echo $this->escapeHtml($this->getMasterWebsiteName()); ?></td>
+                        <td>&nbsp;-&gt;&nbsp;<?php echo $this->escapeHtml($this->getStagingWebsiteName()); ?></td>
                     </tr>
                     </table>
                 </div>
@@ -60,7 +60,7 @@
                     <?php else:?>
                     <?php foreach ($_map as $view): ?>
                     <tr>
-                        <td><?php echo $view['name'] ?></td>
+                        <td><?php echo $this->escapeHtml($view['name']); ?></td>
                     </tr>
                     <?php endforeach; ?>
                     <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/enterprise/staging/staging/edit/tabs/website.phtml app/design/adminhtml/default/default/template/enterprise/staging/staging/edit/tabs/website.phtml
index 994aecc..542afe1 100644
--- app/design/adminhtml/default/default/template/enterprise/staging/staging/edit/tabs/website.phtml
+++ app/design/adminhtml/default/default/template/enterprise/staging/staging/edit/tabs/website.phtml
@@ -29,7 +29,7 @@
 <div id="staging_store_container">
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View') ?>:</label>
 <select multiple="multiple" name="staging[selected_stores]" id="staging_selected_stores" class="left-col-block">
-    <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+    <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
     <?php foreach ($_websiteCollection as $_website): ?>
         <?php $showWebsite=false; ?>
         <?php foreach ($this->getGroupCollection($_website) as $_group): ?>
@@ -37,13 +37,13 @@
             <?php foreach ($this->getStoreCollection($_group) as $_store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <optgroup label="<?php echo $this->getWebsiteName($_website) ?>"></optgroup>
+                    <optgroup label="<?php echo $this->escapeHtml($this->getWebsiteName($_website)); ?>"></optgroup>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>">
+                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>">
                 <?php endif; ?>
-                <option group="<?php echo $_group->getId() ?>" value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option group="<?php echo $_group->getId() ?>" value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/enterprise/staging/staging/edit/tabs/website/store.phtml app/design/adminhtml/default/default/template/enterprise/staging/staging/edit/tabs/website/store.phtml
index 2878748..a930882 100644
--- app/design/adminhtml/default/default/template/enterprise/staging/staging/edit/tabs/website/store.phtml
+++ app/design/adminhtml/default/default/template/enterprise/staging/staging/edit/tabs/website/store.phtml
@@ -35,7 +35,7 @@
 <select name="staging_website_stores" id="staging_website_stores_<?php echo $this->getWebsite()->getId(); ?>" class="left-col-block">
     <option value=""><?php echo $this->__('Please, select a store view') ?></option>
     <?php foreach ($_storeCollection as $_store): ?>
-        <option value="<?php echo $_store->getId() ?>"><?php echo $_store->getName() ?></option>
+        <option value="<?php echo $_store->getId() ?>"><?php echo $this->escapeHtml($_store->getName()); ?></option>
     <?php endforeach; ?>
 </select>
 <button class="button" onclick="addStagingStore('<?php echo $this->getWebsite()->getId(); ?>'); return false;"><span><?php echo $this->__('Add'); ?></span></button>
diff --git app/design/adminhtml/default/default/template/enterprise/staging/staging/merge/settings/website.phtml app/design/adminhtml/default/default/template/enterprise/staging/staging/merge/settings/website.phtml
index 1ab39f9..75e1c4a 100644
--- app/design/adminhtml/default/default/template/enterprise/staging/staging/merge/settings/website.phtml
+++ app/design/adminhtml/default/default/template/enterprise/staging/staging/merge/settings/website.phtml
@@ -31,7 +31,7 @@
 <?php $stagingWebsites  = $this->getStagingWebsiteCollection(); ?>
 <?php $stagingWebsite   = $staging->getStagingWebsite(); ?>
 <div>
-    <h3 class="icon-head head-categories"><?php echo $staging->getName(); ?></h3>
+    <h3 class="icon-head head-categories"><?php echo $this->escapeHtml($staging->getName()); ?></h3>
 </div>
 <?php if($this->getPagerVisibility() || $this->getExportTypes() || $this->getFilterVisibility()): ?>
     <table cellspacing="0" class="actions">
@@ -130,13 +130,13 @@
             <tr id="<?php echo $this->getId() ?>_website_template" style="display: none;">
                 <td class="mapper-name"><?php echo $this->__('Staging Website: '); ?>&nbsp;&nbsp;&nbsp;
                     <input type="hidden" name="map[websites][from][]" class="validate-select-website staging-mapper-website-from" value="<?php echo $stagingWebsite->getId(); ?>" />
-                    <span><?php echo $stagingWebsite->getName(); ?></span>
+                    <span><?php echo $this->escapeHtml($stagingWebsite->getName()); ?></span>
                 </td>
                 <td class="mapper-select"><?php echo $this->__('Website: '); ?>&nbsp;&nbsp;&nbsp;
                     <select name="map[websites][to][]" class="validate-select-website staging-mapper-website-to">
                         <option value=""><?php echo $this->__('Select website to map'); ?></option>
                     <?php foreach ($masterWebsites as $website): ?>
-                        <option value="<?php echo $website->getId(); ?>"><?php echo $website->getName(); ?></option>
+                        <option value="<?php echo $website->getId(); ?>"><?php echo $this->escapeHtml($website->getName()); ?></option>
                     <?php endforeach; ?>
                     </select>
                 </td>
diff --git app/design/adminhtml/default/default/template/enterprise/store/switcher.phtml app/design/adminhtml/default/default/template/enterprise/store/switcher.phtml
index 31b62d8..725a10e 100644
--- app/design/adminhtml/default/default/template/enterprise/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/enterprise/store/switcher.phtml
@@ -29,7 +29,7 @@
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View') ?>:</label>
 <select name="store_switcher" id="store_switcher" class="left-col-block" onchange="return switchStore(this);">
     <?php if( $this->helper('permissions')->isSuperAdmin() ):?>
-        <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+        <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
     <?php endif;?>
     <?php foreach ($_websiteCollection as $_website): ?>
         <?php $showWebsite=false; ?>
@@ -42,13 +42,13 @@
                 endif;?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <optgroup label="<?php echo $this->getWebsiteName($_website) ?>"></optgroup>
+                    <optgroup label="<?php echo $this->escapeHtml($this->getWebsiteName($_website)); ?>"></optgroup>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>">
+                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>">
                 <?php endif; ?>
-                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/enterprise/store/switcher/enhanced.phtml app/design/adminhtml/default/default/template/enterprise/store/switcher/enhanced.phtml
index 6b3eb99..69e2936 100644
--- app/design/adminhtml/default/default/template/enterprise/store/switcher/enhanced.phtml
+++ app/design/adminhtml/default/default/template/enterprise/store/switcher/enhanced.phtml
@@ -30,7 +30,7 @@
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View') ?>:</label>
 <select name="store_switcher" id="store_switcher" class="left-col-block">
     <?php if( $this->helper('permissions')->isSuperAdmin() ):?>
-        <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+        <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
     <?php endif;?>
     <?php foreach ($_websiteCollection as $_website): ?>
         <?php $showWebsite=false; ?>
@@ -43,13 +43,13 @@
                 endif;?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <optgroup label="<?php echo $this->getWebsiteName($_website) ?>"></optgroup>
+                    <optgroup label="<?php echo $this->escapeHtml($this->getWebsiteName($_website)); ?>"></optgroup>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>">
+                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>">
                 <?php endif; ?>
-                <option group="<?php echo $_group->getId() ?>" value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option group="<?php echo $_group->getId() ?>" value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/newsletter/preview/store.phtml app/design/adminhtml/default/default/template/newsletter/preview/store.phtml
index 84a491d..1a51932 100644
--- app/design/adminhtml/default/default/template/newsletter/preview/store.phtml
+++ app/design/adminhtml/default/default/template/newsletter/preview/store.phtml
@@ -35,13 +35,13 @@
             <?php foreach ($this->getStores($group) as $store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <optgroup label="<?php echo $website->getName() ?>"></optgroup>
+                    <optgroup label="<?php echo $this->escapeHtml($website->getName()); ?>"></optgroup>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $group->getName() ?>">
+                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($group->getName()); ?>">
                 <?php endif; ?>
-                <option value="<?php echo $store->getId() ?>"<?php if($this->getStoreId() == $store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $store->getName() ?></option>
+                <option value="<?php echo $store->getId() ?>"<?php if($this->getStoreId() == $store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/report/store/switcher.phtml app/design/adminhtml/default/default/template/report/store/switcher.phtml
index 2a7dc15..12b1e76 100644
--- app/design/adminhtml/default/default/template/report/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/report/store/switcher.phtml
@@ -40,14 +40,14 @@
             <?php foreach ($this->getStoreCollection($_group) as $_store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <option website="true" value="<?php echo $_website->getId() ?>"<?php if($this->getRequest()->getParam('website') == $_website->getId()): ?> selected<?php endif; ?>><?php echo $_website->getName() ?></option>
+                    <option website="true" value="<?php echo $_website->getId() ?>"<?php if($this->getRequest()->getParam('website') == $_website->getId()): ?> selected<?php endif; ?>><?php echo $this->escapeHtml($_website->getName()); ?></option>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <!--optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>"-->
-                    <option group="true" value="<?php echo $_group->getId() ?>"<?php if($this->getRequest()->getParam('group') == $_group->getId()): ?> selected<?php endif; ?>>&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?></option>
+                    <!--optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>"-->
+                    <option group="true" value="<?php echo $_group->getId() ?>"<?php if($this->getRequest()->getParam('group') == $_group->getId()): ?> selected<?php endif; ?>>&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?></option>
                 <?php endif; ?>
-                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index 233ea32..c36e36e 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -63,7 +63,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             </tr>
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Purchased From') ?></label></td>
-                <td class="value"><strong><?php echo $this->getOrderStoreName() ?></strong></td>
+                <td class="value"><strong><?php echo $this->getOrderStoreName(); ?></strong></td>
             </tr>
             <?php if($_order->getRelationChildId()): ?>
             <tr>
diff --git app/design/adminhtml/default/default/template/store/switcher.phtml app/design/adminhtml/default/default/template/store/switcher.phtml
index bf45f42..1fc65e0 100644
--- app/design/adminhtml/default/default/template/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/store/switcher.phtml
@@ -28,7 +28,7 @@
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View') ?>:</label>
 <select name="store_switcher" id="store_switcher" onchange="return switchStore(this);">
 <?php if ($this->hasDefaultOption()): ?>
-    <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+    <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
 <?php endif; ?>
     <?php foreach ($websites as $website): ?>
         <?php $showWebsite=false; ?>
diff --git app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
index 34e4915..3dc2ad4 100644
--- app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
+++ app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
@@ -29,7 +29,7 @@
 <div id="store_switcher_container">
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View') ?>:</label>
 <select name="store_switcher" id="store_switcher" class="left-col-block">
-    <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+    <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
     <?php foreach ($_websiteCollection as $_website): ?>
         <?php $showWebsite=false; ?>
         <?php foreach ($this->getGroupCollection($_website) as $_group): ?>
@@ -37,13 +37,13 @@
             <?php foreach ($this->getStoreCollection($_group) as $_store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <optgroup label="<?php echo $_website->getName() ?>"></optgroup>
+                    <optgroup label="<?php echo $this->escapeHtml($_website->getName()); ?>"></optgroup>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>">
+                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>">
                 <?php endif; ?>
-                <option group="<?php echo $_group->getId() ?>" value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option group="<?php echo $_group->getId() ?>" value="<?php echo $_store->getId(); ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/system/convert/profile/wizard.phtml app/design/adminhtml/default/default/template/system/convert/profile/wizard.phtml
index 6cf6d4e..edb65fb 100644
--- app/design/adminhtml/default/default/template/system/convert/profile/wizard.phtml
+++ app/design/adminhtml/default/default/template/system/convert/profile/wizard.phtml
@@ -203,9 +203,9 @@ Event.observe(window, 'load', function(){
                                 <?php endif; ?>
                                 <?php if (!$_groupShow): ?>
                                     <?php $_groupShow=true; ?>
-                                    <optgroup label="&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>">
+                                    <optgroup label="&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>">
                                 <?php endif; ?>
-                                <option value="<?php echo $_store->getId() ?>" <?php echo $this->getSelected('store_id', $_store->getId()) ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                                <option value="<?php echo $_store->getId() ?>" <?php echo $this->getSelected('store_id', $_store->getId()) ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
                             <?php endforeach; ?>
                             <?php if ($_groupShow): ?>
                                 </optgroup>
diff --git app/design/adminhtml/default/default/template/tax/rate/title.phtml app/design/adminhtml/default/default/template/tax/rate/title.phtml
index c908606..0528c35 100644
--- app/design/adminhtml/default/default/template/tax/rate/title.phtml
+++ app/design/adminhtml/default/default/template/tax/rate/title.phtml
@@ -27,7 +27,7 @@
 <?php /* <table class="dynamic-grid" cellspacing="0" id="tax-rate-titles-table"> */ ?>
     <tr class="dynamic-grid">
     <?php foreach ($this->getStores() as $_store): ?>
-        <th><?php echo $_store->getName() ?></th>
+        <th><?php echo $this->escapeHtml($_store->getName()); ?></th>
     <?php endforeach; ?>
     </tr>
     <tr class="dynamic-grid">
diff --git app/design/adminhtml/default/default/template/widget/form/renderer/fieldset.phtml app/design/adminhtml/default/default/template/widget/form/renderer/fieldset.phtml
index 9b05cc4..e693b44 100644
--- app/design/adminhtml/default/default/template/widget/form/renderer/fieldset.phtml
+++ app/design/adminhtml/default/default/template/widget/form/renderer/fieldset.phtml
@@ -30,7 +30,7 @@
 <?php endif; ?>
 <?php if ($_element->getLegend()): ?>
 <div class="entry-edit-head">
-    <h4 class="icon-head head-edit-form fieldset-legend"><?php echo $_element->getLegend() ?></h4>
+    <h4 class="icon-head head-edit-form fieldset-legend"><?php echo $this->escapeHtml($_element->getLegend()) ?></h4>
     <div class="form-buttons"><?php echo $_element->getHeaderBar() ?></div>
 </div>
 <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
index 8e39b16..bddd17a 100644
--- app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
+++ app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
@@ -45,7 +45,7 @@
 
         <?php foreach ($this->getNodesInRange() as $node):?>
             <?php if ($node->getIsCurrent()):?>
-                <li class="current"><?php echo $this->getNodeLabel($node)?></li>
+                <li class="current"><?php echo $this->escapeHtml($this->getNodeLabel($node))?></li>
             <?php else: ?>
                 <li><a title="<?php echo $this->htmlEscape($node->getLabel())?>" href="<?php echo $node->getUrl()?>"><?php echo $this->getNodeLabel($node)?></a></li>
             <?php endif; ?>
diff --git app/locale/en_US/Mage_Catalog.csv app/locale/en_US/Mage_Catalog.csv
index ac5d413..f4f221a 100644
--- app/locale/en_US/Mage_Catalog.csv
+++ app/locale/en_US/Mage_Catalog.csv
@@ -626,6 +626,7 @@
 "The product has been deleted.","The product has been deleted."
 "The product has been duplicated.","The product has been duplicated."
 "The product has been saved.","The product has been saved."
+"HTML tags are not allowed in SKU attribute.","HTML tags are not allowed in SKU attribute."
 "The product has required options","The product has required options"
 "The review has been deleted","The review has been deleted"
 "The review has been saved.","The review has been saved."
diff --git app/locale/en_US/Mage_ImportExport.csv app/locale/en_US/Mage_ImportExport.csv
index 029ea5d..6aa7d05 100644
--- app/locale/en_US/Mage_ImportExport.csv
+++ app/locale/en_US/Mage_ImportExport.csv
@@ -1,4 +1,6 @@
 " in rows: "," in rows: "
+"Invalid value in SKU column. HTML tags are not allowed","Invalid value in SKU column. HTML tags are not allowed"
+"Incorrect entity type","Incorrect entity type"
 "-- Please Select --","-- Please Select --"
 "Adapter must be an instance of Mage_ImportExport_Model_Import_Adapter_Abstract","Adapter must be an instance of Mage_ImportExport_Model_Import_Adapter_Abstract"
 "Adapter type must be a non empty string","Adapter type must be a non empty string"
diff --git lib/Zend/Mail/Transport/Sendmail.php lib/Zend/Mail/Transport/Sendmail.php
index b27f81d..c495e08 100644
--- lib/Zend/Mail/Transport/Sendmail.php
+++ lib/Zend/Mail/Transport/Sendmail.php
@@ -119,8 +119,9 @@ class Zend_Mail_Transport_Sendmail extends Zend_Mail_Transport_Abstract
                 );
             }
 
+            $fromEmailHeader = str_replace(' ', '', $this->parameters);
             // Sanitize the From header
-            if (!Zend_Validate::is(str_replace(' ', '', $this->parameters), 'EmailAddress')) {
+            if (!Zend_Validate::is($fromEmailHeader, 'EmailAddress')) {
                 throw new Zend_Mail_Transport_Exception('Potential code injection in From header');
             } else {
                 set_error_handler(array($this, '_handleMailErrors'));
@@ -129,7 +130,7 @@ class Zend_Mail_Transport_Sendmail extends Zend_Mail_Transport_Abstract
                     $this->_mail->getSubject(),
                     $this->body,
                     $this->header,
-                    $this->parameters);
+                    $fromEmailHeader);
                 restore_error_handler();
             }
         }
