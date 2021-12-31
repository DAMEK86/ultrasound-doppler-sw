#include <linux/of.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fpga/fpga-mgr.h>


static int __init fpga_loader_init(void)
{
        /* device node that specifies the FPGA manager to use */
        struct device_node *mgr_node;

        struct fpga_image_info *image_info;

        int ret;
        struct fpga_manager *mgr;

        printk(KERN_INFO "Hello\n");

        mgr_node = of_find_node_by_name(NULL, "ice40");
        if (!mgr_node) {
                pr_err("Failed to find node\n");
                return -PTR_ERR(mgr_node);
        }

        /* Get exclusive control of FPGA manager */
        mgr = of_fpga_mgr_get(mgr_node);

        image_info = fpga_image_info_alloc(&mgr->dev);
        /* FPGA image is in this file which is in the firmware search path */
        image_info->firmware_name = "counter-reverse.bin";
        /* flags indicates whether to do full or partial reconfiguration */
        image_info->flags = 0;

        /* Get the firmware image (path) and load it to the FPGA */
        ret = fpga_mgr_load(mgr, image_info);
        if(ret) {
                pr_err("Failed to load FW\n");
                goto out_free_image_info;
        }

        /* Release the FPGA manager */
        fpga_mgr_put(mgr);

out_free_image_info:
        fpga_image_info_free(image_info);

        return ret;
}

static void __exit ModuleExit(void) {
        printk("Bye\n");
}

module_init(fpga_loader_init);
module_exit(ModuleExit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Andreas Rehn <rehn.andreas86@gmail.com");
MODULE_DESCRIPTION("A simple FPGA loader");
