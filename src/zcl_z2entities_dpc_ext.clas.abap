class ZCL_Z2ENTITIES_DPC_EXT definition
  public
  inheriting from ZCL_Z2ENTITIES_DPC
  create public .

public section.
protected section.

  methods PRODUCTSET_GET_ENTITY
    redefinition .
  methods PRODUCTSET_GET_ENTITYSET
    redefinition .
  methods SUPPLIERSET_GET_ENTITYSET
    redefinition .
  methods SUPPLIERSET_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_Z2ENTITIES_DPC_EXT IMPLEMENTATION.


  METHOD productset_get_entity.
    DATA: ls_keyprp     LIKE LINE OF it_key_tab,
          ls_productid  TYPE bapi_epm_product_id,
          ls_headerdata TYPE bapi_epm_product_header.

    READ TABLE it_key_tab INTO ls_keyprp WITH KEY name = 'ProductID'.
    IF sy-subrc EQ 0.
      ls_productid-product_id = ls_keyprp-value.

      CALL FUNCTION 'BAPI_EPM_PRODUCT_GET_DETAIL'
        EXPORTING
          product_id = ls_productid
        IMPORTING
          headerdata = ls_headerdata
*       TABLES
*         CONVERSION_FACTORS       =
*         RETURN     =
        .
      er_entity-productid   = ls_headerdata-product_id.
      er_entity-typecode    = ls_headerdata-type_code.
      er_entity-category    = ls_headerdata-category.
      er_entity-name        = ls_headerdata-name.
      er_entity-description = ls_headerdata-description.
      er_entity-supplierid  = ls_headerdata-supplier_id.
    ENDIF.
  ENDMETHOD.


  METHOD productset_get_entityset.
    DATA: lt_headerdata TYPE TABLE OF bapi_epm_product_header,
          ls_headerdata TYPE bapi_epm_product_header,
          ls_entityset  LIKE LINE OF et_entityset.

    CALL FUNCTION 'BAPI_EPM_PRODUCT_GET_LIST'
* EXPORTING
*   MAX_ROWS                    =
      TABLES
        headerdata = lt_headerdata
*       SELPARAMPRODUCTID           =
*       SELPARAMSUPPLIERNAMES       =
*       SELPARAMCATEGORIES          =
*       RETURN     =
      .

    IF lt_headerdata IS NOT INITIAL.
      LOOP AT lt_headerdata INTO ls_headerdata.
        CLEAR: ls_entityset.

        ls_entityset-productid   = ls_headerdata-product_id.
        ls_entityset-typecode    = ls_headerdata-type_code.
        ls_entityset-category    = ls_headerdata-category.
        ls_entityset-name        = ls_headerdata-name.
        ls_entityset-description = ls_headerdata-description.
        ls_entityset-supplierid  = ls_headerdata-supplier_id.

        APPEND ls_entityset TO et_entityset.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD supplierset_get_entity.
    DATA: ls_keyprp         LIKE LINE OF it_key_tab,
          ls_bpid           TYPE bapi_epm_bp_id,
          ls_headerdata     TYPE bapi_epm_bp_header,
          ls_product_entity TYPE zcl_z2entities_mpc=>ts_product.

    READ TABLE it_key_tab INTO ls_keyprp INDEX 1.
    IF sy-subrc EQ 0.
      CASE ls_keyprp-name.
        WHEN 'SupplierID'.
          ls_bpid-bp_id = ls_keyprp-value.
        WHEN 'ProductID'.
          TRY.
              CALL METHOD me->productset_get_entity
                EXPORTING
                  iv_entity_name     = iv_entity_name
                  iv_entity_set_name = iv_entity_set_name
                  iv_source_name     = iv_source_name
                  it_key_tab         = it_key_tab
                  it_navigation_path = it_navigation_path
                IMPORTING
                  er_entity          = ls_product_entity.

            CATCH /iwbep/cx_mgw_busi_exception .
            CATCH /iwbep/cx_mgw_tech_exception .
          ENDTRY.

          IF ls_product_entity IS NOT INITIAL.
            ls_bpid-bp_id = ls_product_entity-supplierid.
          ENDIF.
        WHEN OTHERS.
*Do Nothing
      ENDCASE.

      CALL FUNCTION 'BAPI_EPM_BP_GET_DETAIL'
        EXPORTING
          bp_id      = ls_bpid
        IMPORTING
          headerdata = ls_headerdata.

      er_entity-supplierid   = ls_headerdata-bp_id.
      er_entity-suppliername = ls_headerdata-company_name.
    ENDIF.
  ENDMETHOD.


  METHOD supplierset_get_entityset.
    DATA: lt_bpheaderdata TYPE TABLE OF bapi_epm_bp_header,
          ls_bpheaderdata TYPE bapi_epm_bp_header,
          ls_entityset    LIKE LINE OF et_entityset.

    CALL FUNCTION 'BAPI_EPM_BP_GET_LIST'
* EXPORTING
*   MAX_ROWS                  =
      TABLES
*       SELPARAMBPID =
*       SELPARAMCOMPANYNAME       =
        bpheaderdata = lt_bpheaderdata
*       BPCONTACTDATA             =
*       RETURN       =
      .

    IF lt_bpheaderdata IS NOT INITIAL.
      LOOP AT lt_bpheaderdata INTO ls_bpheaderdata.
        ls_entityset-supplierid = ls_bpheaderdata-bp_id.
        ls_entityset-suppliername = ls_bpheaderdata-company_name.

        APPEND ls_entityset TO et_entityset.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
