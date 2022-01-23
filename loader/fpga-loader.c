#include <linux/clk.h>
#include <linux/fpga/fpga-mgr.h>
#include <linux/errno.h>
#include <linux/i2c.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/regmap.h>

#define DRIVER_NAME "usd2022"
#define FALLBACK_FPGA_MANAGER_NODE_NAME "ice40"

struct usd2022 {
        struct i2c_client *client;	/* I2C client */

        /* Regmap */
	struct regmap *regmap;

        /* Device settings */
	unsigned long xtal_freq;	/* Ref Oscillator freq in Hz */

        /* Driver private variables */
        const char* fw_name;
        const char* fpga_mgr_name;
};

/* Register map to define preset values */
struct usd2022_reg_map {
	u8 idx;				/* Register index */
	u8 val;				/* Register value */
};

static const struct usd2022_reg_map usd2022_default_map[] = {
	{ 0x00, 0x0A},
        { 0x01, 0x0B},
        { 0x02, 0x0C},
        { 0x03, 0x0D},
};

static const struct regmap_config usd2022_regmap_config = {
	.reg_bits = 8,
	.val_bits = 8,
	.max_register = 0xf,
};

static int usd2022_write(struct usd2022 *ctx, u8 idx, u8 val)
{
	int ret;

	ret = regmap_write(ctx->regmap, idx, val);
	if (ret)
		dev_err(&ctx->client->dev, "write ret(%d): idx 0x%02x val 0x%02x\n",
			ret, idx, val);

	return ret;
}

static void usd2022_preload(struct usd2022 *ctx)
{
        unsigned int i;

        for (i = 0; i < ARRAY_SIZE(usd2022_default_map); i++)
		usd2022_write(ctx, usd2022_default_map[i].idx, usd2022_default_map[i].val);
        
        dev_dbg(&ctx->client->dev, "register preloaded.\n");
};

static int load_firmware(struct usd2022 *ctx)
{
        /* device node that specifies the FPGA manager to use */
        struct device_node *mgr_node;

        struct fpga_image_info *image_info;

        int ret;
        struct fpga_manager *mgr;

        mgr_node = of_find_node_by_name(NULL, "ice40");
        if (!mgr_node) {
                pr_err("Failed to find ice40 node\n");
                return -PTR_ERR(mgr_node);
        }

        /* Get exclusive control of FPGA manager */
        mgr = of_fpga_mgr_get(mgr_node);

        image_info = fpga_image_info_alloc(&mgr->dev);
        /* FPGA image is in this file which is in the firmware search path */
        image_info->firmware_name = devm_kstrdup(&mgr->dev, ctx->fw_name, GFP_KERNEL);
        /* flags indicates whether to do full or partial reconfiguration */
        image_info->flags = 0;

        /* Get the firmware image (path) and load it to the FPGA */
        ret = fpga_mgr_load(mgr, image_info);
        if(ret) {
                pr_err("Failed to load FW\n");
                goto out_free_image_info;
        }

out_free_image_info:
        fpga_image_info_free(image_info);

        /* Release the FPGA manager */
        fpga_mgr_put(mgr);

        return ret;
}

static int usd2022_probe(struct i2c_client *client)
{
        const char* firmware_name;
        const char* fpga_mgr_name;

	struct clk *clk;
        struct usd2022 *ctx;
        int ret;

        if (of_property_read_string(client->dev.of_node, "firmware-name",
				     &firmware_name)) {
                dev_err(&client->dev, "node firmware-name not found.\n");
		return -EINVAL;
        }

        if (of_property_read_string(client->dev.of_node, "fpga-mgr-name",
				     &fpga_mgr_name)) {
                dev_warn(&client->dev, "node fpga-mgr-name not found, using fallback %s\n", FALLBACK_FPGA_MANAGER_NODE_NAME);
                fpga_mgr_name = kstrdup(FALLBACK_FPGA_MANAGER_NODE_NAME, GFP_KERNEL);
        }

        clk = devm_clk_get(&client->dev, NULL);
	if (IS_ERR(clk)) {
		ret = PTR_ERR(clk);
		dev_err(&client->dev, "cannot get clock %d\n", ret);
		return ret;
	}

        /* Alloc doppler context */
	ctx = devm_kzalloc(&client->dev, sizeof(*ctx), GFP_KERNEL);
	if (ctx == NULL)
		return -ENOMEM;

        ctx->fw_name = firmware_name;
        ctx->fpga_mgr_name = fpga_mgr_name;
        ctx->xtal_freq = clk_get_rate(clk);
        dev_info(&client->dev, "xtal freq: %luHz\n", ctx->xtal_freq);
        
        ctx->regmap = devm_regmap_init_i2c(client, &usd2022_regmap_config);
	if (IS_ERR(ctx->regmap)) {
		ret = PTR_ERR(ctx->regmap);
		dev_err(&client->dev, "regmap init failed %d\n", ret);
		return -ENODEV;
	}

        ret = load_firmware(ctx);

        if (ret)
                return ret;

        dev_info(&client->dev, "firmware %s loaded\n", ctx->fw_name);

	usd2022_preload(ctx);

        return ret;
}


static int usd2022_remove(struct i2c_client *client)
{
	return 0;
}

static const struct i2c_device_id usd2022_id[] = {
	{ DRIVER_NAME, 0},
	{},
};
MODULE_DEVICE_TABLE(i2c, usd2022_id);


#ifdef CONFIG_OF
static const struct of_device_id usd2022_dt_match[] = {
	{ .compatible = "ice40,usd2022", },
	{ }
};
MODULE_DEVICE_TABLE(of, usd2022_dt_match);
#endif

static struct i2c_driver usd2022_driver = {
	.driver = {
		.name	= DRIVER_NAME,
		.of_match_table = of_match_ptr(usd2022_dt_match),
	},
	.probe_new	= usd2022_probe,
	.remove		= usd2022_remove,
	.id_table	= usd2022_id,
};

module_i2c_driver(usd2022_driver);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Andreas Rehn <rehn.andreas86@gmail.com");
MODULE_DESCRIPTION("Ultrasound doppler driver based on ice40 using fpga manager for loading firmware");
